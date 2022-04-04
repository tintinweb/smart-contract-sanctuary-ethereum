/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.11;



// Part: IDipFabDAOextension

/// @notice DipFab DAO membership extension interface.
interface IDipFabDAOextension {
    function setExtension(bytes calldata extensionData) external;

    function callExtension(
        address account, 
        uint256 amount, 
        bytes calldata extensionData
    ) external payable returns (bool mint, uint256 amountOut);
}

// Part: IDipFabWhitelistManager

/// @notice DipFab DAO whitelist manager interface.
interface IDipFabWhitelistManager {
    function whitelistedAccounts(uint256 listId, address account) external returns (bool);
}

// Part: ReentrancyGuard

contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant NOT_ENTERED = 1;

    uint256 private constant ENTERED = 2;

    uint256 private status = NOT_ENTERED;

    modifier nonReentrant() {
        if (status == ENTERED) revert Reentrancy();

        status = ENTERED;

        _;

        status = NOT_ENTERED;
    }
}

// Part: SafeTransferLib

/// @notice Safe ETH and ERC-20 transfer library that gracefully handles missing return values.
/// @author Modified from SolMate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error ETHtransferFailed();

    error TransferFailed();

    error TransferFromFailed();

    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function _safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // transfer the ETH and store if it succeeded or not
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        if (!callStatus) revert ETHtransferFailed();
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // begin with the function selector
            
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument
            
            mstore(add(freeMemoryPointer, 36), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

            // call the token and store if it succeeded or not
            // we use 68 because the calldata length is 4 + 32 * 2
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        if (!_didLastOptionalReturnCallSucceed(callStatus)) revert TransferFailed();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // get a pointer to some free memory
            let freeMemoryPointer := mload(0x40)

            // write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // begin with the function selector
            
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "from" argument
            
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // mask and append the "to" argument
            
            mstore(add(freeMemoryPointer, 68), amount) // finally append the "amount" argument - no mask as it's a full 32 byte value

            // call the token and store if it succeeded or not
            // we use 100 because the calldata length is 4 + 32 * 3
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        if (!_didLastOptionalReturnCallSucceed(callStatus)) revert TransferFromFailed();
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _didLastOptionalReturnCallSucceed(bool callStatus) internal pure returns (bool success) {
        assembly {
            // get how many bytes the call returned
            let returnDataSize := returndatasize()

            // if the call reverted:
            if iszero(callStatus) {
                // copy the revert message into memory
                returndatacopy(0, 0, returnDataSize)

                // revert with the same message
                revert(0, returnDataSize)
            }

            switch returnDataSize
            
            case 32 {
                // copy the return data into memory
                returndatacopy(0, 0, returnDataSize)

                // set success to whether it returned true
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // there was no return data
                success := 1
            }
            default {
                // it returned some malformed input
                success := 0
            }
        }
    }
}

// File: DipFabDAOcrowdsale.sol

/// @notice Crowdsale contract that receives ETH or tokens to mint registered DAO tokens, including merkle whitelisting.
contract DipFabDAOcrowdsale is ReentrancyGuard {
    using SafeTransferLib for address;

    event ExtensionSet(address dao, uint256 listId, address purchaseToken, uint8 purchaseMultiplier, uint96 purchaseLimit, uint32 saleEnds);

    event ExtensionCalled(address indexed dao, address indexed member, uint256 indexed amountOut);

    error NullMultiplier();

    error SaleEnded();

    error NotWhitelisted();

    error PurchaseLimit();
    
    IDipFabWhitelistManager public immutable whitelistManager;

    mapping(address => Crowdsale) public crowdsales;

    struct Crowdsale {
        uint256 listId;
        address purchaseToken;
        uint8 purchaseMultiplier;
        uint96 purchaseLimit;
        uint96 amountPurchased;
        uint32 saleEnds;
    }

    constructor(IDipFabWhitelistManager whitelistManager_) {
        whitelistManager = whitelistManager_;
    }

    function setExtension(bytes calldata extensionData) public nonReentrant virtual {
        (uint256 listId, address purchaseToken, uint8 purchaseMultiplier, uint96 purchaseLimit, uint32 saleEnds) 
            = abi.decode(extensionData, (uint256, address, uint8, uint96, uint32));
        
        if (purchaseMultiplier == 0) revert NullMultiplier();

        crowdsales[msg.sender] = Crowdsale({
            listId: listId,
            purchaseToken: purchaseToken,
            purchaseMultiplier: purchaseMultiplier,
            purchaseLimit: purchaseLimit,
            amountPurchased: 0,
            saleEnds: saleEnds
        });

        emit ExtensionSet(msg.sender, listId, purchaseToken, purchaseMultiplier, purchaseLimit, saleEnds);
    }

    function callExtension(address dao, uint256 amount) public payable nonReentrant virtual returns (uint256 amountOut) {
        Crowdsale storage sale = crowdsales[dao];

        bytes memory extensionData = abi.encode(true);

        if (block.timestamp > sale.saleEnds) revert SaleEnded();

        if (sale.listId != 0) 
            if (!whitelistManager.whitelistedAccounts(sale.listId, msg.sender)) revert NotWhitelisted();

        if (sale.purchaseToken == address(0)) {
            amountOut = msg.value * sale.purchaseMultiplier;

            if (sale.amountPurchased + amountOut > sale.purchaseLimit) revert PurchaseLimit();

            // send ETH to DAO
            dao._safeTransferETH(msg.value);

            sale.amountPurchased += uint96(amountOut);

            IDipFabDAOextension(dao).callExtension(msg.sender, amountOut, extensionData);
        } else {
            // send tokens to DAO
            sale.purchaseToken._safeTransferFrom(msg.sender, dao, amount);

            amountOut = amount * sale.purchaseMultiplier;

            if (sale.amountPurchased + amountOut > sale.purchaseLimit) revert PurchaseLimit();

            sale.amountPurchased += uint96(amountOut);

            IDipFabDAOextension(dao).callExtension(msg.sender, amountOut, extensionData);
        }

        emit ExtensionCalled(msg.sender, dao, amountOut);
    }
}