// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./Adminable.sol";
import "./DelegatorInterface.sol";
import "./interfaces/DexAggregatorInterface.sol";
import "./interfaces/OpenLevInterface.sol";

contract OPLimitOrderDelegator is DelegatorInterface, Adminable {
    constructor(
        OpenLevInterface _openLev,
        DexAggregatorInterface _dexAgg,
        address payable _admin,
        address implementation_
    ) {
        admin = payable(msg.sender);
        // Creator of the contract is admin during initialization
        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation_, abi.encodeWithSignature("initialize(address,address)", _openLev, _dexAgg));
        implementation = implementation_;

        // Set the proper admin now that initialization is done
        admin = _admin;
    }

    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public override onlyAdmin {
        address oldImplementation = implementation;
        implementation = implementation_;
        emit NewImplementation(oldImplementation, implementation);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >0.7.6;

pragma experimental ABIEncoderV2;

/**
 * @title OpenLevInterface
 * @author OpenLeverage
 */
interface OpenLevInterface {
    struct Market {
        // Market info
        address pool0; // Lending Pool 0
        address pool1; // Lending Pool 1
        address token0; // Lending Token 0
        address token1; // Lending Token 1
        uint16 marginLimit; // Margin ratio limit for specific trading pair. Two decimal in percentage, ex. 15.32% => 1532
        uint16 feesRate; // feesRate 30=>0.3%
        uint16 priceDiffientRatio;
        address priceUpdater;
        uint256 pool0Insurance; // Insurance balance for token 0
        uint256 pool1Insurance; // Insurance balance for token 1
    }

    struct Trade {
        // Trade storage
        uint256 deposited; // Balance of deposit token
        uint256 held; // Balance of held position
        bool depositToken; // Indicate if the deposit token is token 0 or token 1
        uint128 lastBlockNum; // Block number when the trade was touched last time, to prevent more than one operation within same block
    }

    function markets(uint16 marketId) external view returns (Market memory market);

    function activeTrades(
        address trader,
        uint16 marketId,
        bool longToken
    ) external view returns (Trade memory trade);

    function updatePrice(uint16 marketId, bytes memory dexData) external;

    function marginTradeFor(
        address trader,
        uint16 marketId,
        bool longToken,
        bool depositToken,
        uint256 deposit,
        uint256 borrow,
        uint256 minBuyAmount,
        bytes memory dexData
    ) external payable returns (uint256 newHeld);

    function closeTradeFor(
        address trader,
        uint16 marketId,
        bool longToken,
        uint256 closeHeld,
        uint256 minOrMaxAmount,
        bytes memory dexData
    ) external returns (uint256 depositReturn);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >0.7.6;
pragma experimental ABIEncoderV2;

interface DexAggregatorInterface {
    function getPrice(
        address desToken,
        address quoteToken,
        bytes memory data
    ) external view returns (uint256 price, uint8 decimals);

    function getPriceCAvgPriceHAvgPrice(
        address desToken,
        address quoteToken,
        uint32 secondsAgo,
        bytes memory dexData
    )
        external
        view
        returns (
            uint256 price,
            uint256 cAvgPrice,
            uint256 hAvgPrice,
            uint8 decimals,
            uint256 timestamp
        );

    function updatePriceOracle(
        address desToken,
        address quoteToken,
        uint32 timeWindow,
        bytes memory data
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >0.7.6;

abstract contract DelegatorInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

    /**
     * Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     */
    function setImplementation(address implementation_) public virtual;

    /**
     * Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    /**
     * Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data) public returns (bytes memory) {
        return delegateTo(implementation, data);
    }

    /**
     * Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        // delegate all other functions to current implementation
        if (msg.data.length > 0) {
            (bool success, ) = implementation.delegatecall(msg.data);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize())
                switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >0.7.6;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() {
        developer = payable(msg.sender);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "caller must be admin or developer");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "only pendingAdmin can accept admin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = payable(oldPendingAdmin);
        // Clear the pending value
        pendingAdmin = payable(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
}