// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IBlxPresale {

    function presaleSoftCapStatus() external view returns(bool);
    function presaleClosed() external view returns(bool);
    function rewardBurnt() external view returns(bool);
    function updateReferrer(address user, address referrer, uint amount, uint blx) external;
    function claimRewards(address referrer) external returns (uint blx, uint rewards);
    function burnRemainingBLX() external;
    function purchase(uint amount, address referrer, address sender, bool collectFee) external;
    function refund(address msgSender) external returns (uint amount, bool alreadyRedeemed);
    function blxObligation() external view returns (uint amount);
    function daoAgentAddress() external view returns (address daoAgentAddress);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IIBCO {

    function softCapStatus() external view returns(bool);
    function closed() external view returns(bool);    
    function purchase(uint blxAmount, uint maxUsdc, address referrer, address sender, bool collectFee) external;
    function ibcoEnd() external returns (uint);
    function started() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/Sale/IBlxPresale.sol";
import "../interfaces/Sale/IIBCO.sol";

/* provide 'batched' tx for permit then sale, mainly designed for metatx(like biconomy forwarder) usage where
 * only 2 signature(permit and biconomy call to this) is needed instead of 3 (permit, bicononmy call to presale/ibco, biconomy call to this)
 * the later 3 sig mode can be done via MultiCall(third one is biconomy call to Multicall)
 */
contract TokenSale is ERC2771Context, Ownable {
    address public usdcAddress;
    address public presaleAddress;
    address public ibcoAddress;

    constructor (address trustedForwarder, address _usdcAddress) ERC2771Context(trustedForwarder) {
        require(trustedForwarder != address(0), "TOKEN:FORWARDER_ADDRESS_ZERO");
        require(_usdcAddress != address(0), "TOKEN:USDC_ADDRESS_ZERO");
        usdcAddress = _usdcAddress;
    }

    function setAddresses(address _presaleAddress, address _ibcoAddress) external onlyOwner {
        require(_presaleAddress != address(0), "TOKEN:PRESALE_ADDRESS_ZERO");
        require(_ibcoAddress != address(0), "TOKEN:IBCO_ADDRESS_ZERO");
        presaleAddress = _presaleAddress;
        ibcoAddress = _ibcoAddress;
    }

    /// @dev enterPresale with optional USDC permit before entering actual sale
    /// @param amount amount in USDC
    /// @param referrer optional referrer(passthrough)
    /// @param permit optional USDC permit calldata
    function enterPresale(uint amount, address referrer, bytes calldata permit, bytes calldata forwarderPermit) external {
        if (permit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(permit);
            _verifyCallResult(success, result, "USDC sale permit failed");
        }
        if (forwarderPermit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(forwarderPermit);
            _verifyCallResult(success, result, "USDC forward permit failed");
        }
        IBlxPresale(presaleAddress).purchase(amount, referrer, _msgSender(), isTrustedForwarder(msg.sender));
    }

    /// @dev enterIBCO with optional USDC permit before entering actual sale
    /// @param blxAmount amount in BLX
    /// @param referrer optional referrer(passthrough)
    /// @param permit optional USDC permit calldata
    function enterIbco(uint blxAmount, uint maxUsdc, address referrer, bytes calldata permit, bytes calldata forwarderPermit) external {
        if (permit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(permit);
            _verifyCallResult(success, result, "USDC sale permit failed");
        }
        if (forwarderPermit.length > 0) {
            (bool success, bytes memory result) = usdcAddress.call(forwarderPermit);
            _verifyCallResult(success, result, "USDC forward permit failed");
        }
        IIBCO(ibcoAddress).purchase(blxAmount, maxUsdc, referrer, _msgSender(),isTrustedForwarder(msg.sender));
    }

    /// @dev pick ERC2771Context over Ownable
    function _msgSender() internal view override(Context, ERC2771Context)
        returns (address sender) {
        sender = ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context)
        returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    /**
     * @dev verifies the call result and bubbles up revert reason for failed calls
     *
     * @param success : outcome of forwarded call
     * @param returndata : returned data from the frowarded call
     * @param errorMessage : fallback error message to show 
     */
     function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure {
        if (!success) {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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