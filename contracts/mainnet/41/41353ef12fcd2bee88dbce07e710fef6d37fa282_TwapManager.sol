/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IQueryableErc20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title The interface of a fully compliant EIP20
 * @dev The interface is defined by https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface IERC20Strict is IQueryableErc20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

/**
 * @title Represents a resource that requires initialization.
 */
contract CustomInitializable {
    bool private _wasInitialized;

    /**
     * @notice Throws if the resource was not initialized yet.
     */
    modifier ifInitialized () {
        require(_wasInitialized, "Not initialized yet");
        _;
    }

    /**
     * @notice Throws if the resource was initialized already.
     */
    modifier ifNotInitialized () {
        require(!_wasInitialized, "Already initialized");
        _;
    }

    /**
     * @notice Marks the resource as initialized.
     */
    function _initializationCompleted () internal ifNotInitialized {
        _wasInitialized = true;
    }
}

/**
 * @title Represents an ownable resource.
 */
contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred (address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) external virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OnOwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner () external virtual view returns (address) {
        return _owner;
    }
}

interface ITwapManager {
    function getTwapPairAddress (address sellingTokenAddress, address buyingTokenAddress) external view returns (address);
}

interface ITwapDeployer {
    function deployTwap (IERC20Strict sellingToken, IERC20Strict buyingToken, address twapOwnerAddr, address traderAddr, address depositorAddr) external;
}

interface ITwapHook {
    function newSyntheticPairDeployed (address sellingTokenAddress, address buyingTokenAddress, address newContractAddress) external;
    function newOrderCreated (address sellingTokenAddress, address buyingTokenAddress, uint256 newDeadline, uint256 targetQty) external;
}

contract TwapManager is ITwapManager, ITwapHook, CustomOwnable, CustomInitializable {
    struct OrderEntry {
        address sellingTokenAddress;
        address buyingTokenAddress; 
        uint256 deadline;
        uint256 targetQty;
    }

    /// The total number of TWAP orders requested so far
    uint256 public totalOrders;

    /// The contract authorized to deploy TWAP pairs
    address public trustedDeployerContractAddress;

    // The TWAP contract of each synthetic pair
    mapping (bytes32 => address) internal _addresses;

    mapping (uint256 => OrderEntry) internal _orders;

    constructor () {
        _owner = msg.sender;
    }

    function initialize (ITwapDeployer trustedDeployer) external onlyOwner ifNotInitialized {
        require(address(trustedDeployer) != address(0), "Invalid deployer");
        
        trustedDeployerContractAddress = address(trustedDeployer);
        _initializationCompleted();
    }

    function newSyntheticPairDeployed (address sellingTokenAddress, address buyingTokenAddress, address newContractAddress) external override ifInitialized {
        require(msg.sender == trustedDeployerContractAddress, "Invalid sender");

        bytes32 syntheticPair = keccak256(abi.encodePacked(sellingTokenAddress, buyingTokenAddress));
        require(_addresses[syntheticPair] == address(0), "Synthetic Pair already defined");

        _addresses[syntheticPair] = newContractAddress;
    }

    function newOrderCreated (address sellingTokenAddress, address buyingTokenAddress, uint256 newDeadline, uint256 targetQty) external override ifInitialized {
        bytes32 syntheticPair = keccak256(abi.encodePacked(sellingTokenAddress, buyingTokenAddress));
        require(_addresses[syntheticPair] != address(0), "Synthetic Pair not deployed");
        require(msg.sender == _addresses[syntheticPair], "Invalid sender");

        _orders[totalOrders] = OrderEntry(sellingTokenAddress, buyingTokenAddress, newDeadline, targetQty);
        totalOrders++;
    }

    // Gets the address of the TWAP contract responsible for managing the synthetic pair specified.
    function getTwapPairAddress (address sellingTokenAddress, address buyingTokenAddress) public view override returns (address) {
        return _addresses[keccak256(abi.encodePacked(sellingTokenAddress, buyingTokenAddress))];
    }

    function getOrder (uint256 orderId) external view returns (address sellingTokenAddress, address buyingTokenAddress, uint256 deadline, uint256 targetQty, address twapContractAddr) {
        require(_orders[orderId].sellingTokenAddress != address(0), "Invalid ID");

        sellingTokenAddress = _orders[orderId].sellingTokenAddress;
        buyingTokenAddress = _orders[orderId].buyingTokenAddress;
        deadline = _orders[orderId].deadline;
        targetQty = _orders[orderId].targetQty;
        twapContractAddr = _addresses[keccak256(abi.encodePacked(sellingTokenAddress, buyingTokenAddress))];
    }
}