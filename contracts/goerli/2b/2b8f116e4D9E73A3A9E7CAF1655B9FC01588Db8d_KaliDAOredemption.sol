// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

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

/// @notice Minimal ERC-20 interface.
interface IERC20minimal { 
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function burnFrom(address from, uint256 amount) external;
}

/// @notice Gas-optimized reentrancy protection.
/// @author Modified from OpenZeppelin 
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
/// License-Identifier: MIT
abstract contract ReentrancyGuard {
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

/// @notice Redemption contract that transfers registered tokens from Kali DAO in proportion to burnt DAO tokens.
contract KaliDAOredemption is ReentrancyGuard {
    using SafeTransferLib for address;

    event ExtensionSet(address indexed dao, address[] tokens, uint256 indexed redemptionStart);

    event ExtensionCalled(address indexed dao, address indexed member, uint256 indexed amountBurned);

    event TokensAdded(address indexed dao, address[] tokens);

    event TokensRemoved(address indexed dao, uint256[] tokenIndex);

    error NullTokens();

    error NotStarted();

    mapping(address => address[]) public redeemables;

    mapping(address => uint256) public redemptionStarts;

    function getRedeemables(address dao) public view virtual returns (address[] memory tokens) {
        tokens = redeemables[dao];
    }

    function setExtension(bytes calldata extensionData) public nonReentrant virtual {
        (address[] memory tokens, uint256 redemptionStart) = abi.decode(extensionData, (address[], uint256));

        if (tokens.length == 0) revert NullTokens();

        // if redeemables are already set, this call will be interpreted as reset
        if (redeemables[msg.sender].length != 0) delete redeemables[msg.sender];
        
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                redeemables[msg.sender].push(tokens[i]);
            }
        }

        redemptionStarts[msg.sender] = redemptionStart;

        emit ExtensionSet(msg.sender, tokens, redemptionStart);
    }

    function callExtension(
        address account, 
        uint256 amount, 
        bytes calldata
    ) public nonReentrant virtual returns (bool mint, uint256 amountOut) {
        if (block.timestamp < redemptionStarts[msg.sender]) revert NotStarted();

        for (uint256 i; i < redeemables[msg.sender].length;) {
            // calculate fair share of given token for redemption
            uint256 amountToRedeem = amount * 
                IERC20minimal(redeemables[msg.sender][i]).balanceOf(msg.sender) / 
                IERC20minimal(msg.sender).totalSupply();
            
            // `transferFrom` DAO to redeemer
            if (amountToRedeem != 0) {
                address(redeemables[msg.sender][i])._safeTransferFrom(
                    msg.sender, 
                    account, 
                    amountToRedeem
                );
            }

            // cannot realistically overflow on human timescales
            unchecked {
                i++;
            }
        }

        // placeholder values to conform to interface and disclaim mint
        (mint, amountOut) = (false, amount);

        emit ExtensionCalled(msg.sender, account, amount);
    }

    function addTokens(address[] calldata tokens) public nonReentrant virtual {
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                redeemables[msg.sender].push(tokens[i]);
            }
        }

        emit TokensAdded(msg.sender, tokens);
    }

    function removeTokens(uint256[] calldata tokenIndex) public nonReentrant virtual {
        for (uint256 i; i < tokenIndex.length; i++) {
            // move last token to replace indexed spot and pop array to remove last token
            redeemables[msg.sender][tokenIndex[i]] = 
                redeemables[msg.sender][redeemables[msg.sender].length - 1];

            redeemables[msg.sender].pop();
        }

        emit TokensRemoved(msg.sender, tokenIndex);
    }
}