// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Elliptic Curve Digital Signature Algorithm (ECDSA) operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library ECDSA {
    error ECDSA__InvalidS();
    error ECDSA__InvalidSignature();
    error ECDSA__InvalidSignatureLength();
    error ECDSA__InvalidV();

    /**
     * @notice recover signer of hashed message from signature
     * @param hash hashed data payload
     * @param signature signed data payload
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        if (signature.length != 65) revert ECDSA__InvalidSignatureLength();

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @notice recover signer of hashed message from signature v, r, and s values
     * @param hash hashed data payload
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     * @return recovered message signer
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) revert ECDSA__InvalidS();
        if (v != 27 && v != 28) revert ECDSA__InvalidV();

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) revert ECDSA__InvalidSignature();

        return signer;
    }

    /**
     * @notice generate an "Ethereum Signed Message" in the format returned by the eth_sign JSON-RPC method
     * @param hash hashed data payload
     * @return signed message hash
     */
    function toEthSignedMessageHash(
        bytes32 hash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165Base } from './IERC165Base.sol';
import { ERC165BaseInternal } from './ERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165Base is IERC165Base, ERC165BaseInternal {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return _supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165BaseInternal } from './IERC165BaseInternal.sol';
import { ERC165BaseStorage } from './ERC165BaseStorage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165BaseInternal is IERC165BaseInternal {
    /**
     * @notice indicates whether an interface is already supported based on the interfaceId
     * @param interfaceId id of interface to check
     * @return bool indicating whether interface is supported
     */
    function _supportsInterface(
        bytes4 interfaceId
    ) internal view returns (bool) {
        return ERC165BaseStorage.layout().supportedInterfaces[interfaceId];
    }

    /**
     * @notice sets status of interface support
     * @param interfaceId id of interface to set status for
     * @param status boolean indicating whether interface will be set as supported
     */
    function _setSupportsInterface(bytes4 interfaceId, bool status) internal {
        if (interfaceId == 0xffffffff) revert ERC165Base__InvalidInterfaceId();
        ERC165BaseStorage.layout().supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC165BaseStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../../interfaces/IERC165.sol';
import { IERC165BaseInternal } from './IERC165BaseInternal.sol';

interface IERC165Base is IERC165, IERC165BaseInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165Internal } from '../../../interfaces/IERC165Internal.sol';

interface IERC165BaseInternal is IERC165Internal {
    error ERC165Base__InvalidInterfaceId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20Base } from './IERC20Base.sol';
import { ERC20BaseInternal } from './ERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 implementation, excluding optional extensions
 */
abstract contract ERC20Base is IERC20Base, ERC20BaseInternal {
    /**
     * @inheritdoc IERC20
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256) {
        return _allowance(holder, spender);
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return _transferFrom(holder, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from './IERC20BaseInternal.sol';
import { ERC20BaseStorage } from './ERC20BaseStorage.sol';

/**
 * @title Base ERC20 internal functions, excluding optional extensions
 */
abstract contract ERC20BaseInternal is IERC20BaseInternal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function _totalSupply() internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().totalSupply;
    }

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function _balanceOf(
        address account
    ) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().balances[account];
    }

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function _allowance(
        address holder,
        address spender
    ) internal view virtual returns (uint256) {
        return ERC20BaseStorage.layout().allowances[holder][spender];
    }

    /**
     * @notice enable spender to spend tokens on behalf of holder
     * @param holder address on whose behalf tokens may be spent
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        if (holder == address(0)) revert ERC20Base__ApproveFromZeroAddress();
        if (spender == address(0)) revert ERC20Base__ApproveToZeroAddress();

        ERC20BaseStorage.layout().allowances[holder][spender] = amount;

        emit Approval(holder, spender, amount);

        return true;
    }

    /**
     * @notice decrease spend amount granted by holder to spender
     * @param holder address on whose behalf tokens may be spent
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     */
    function _decreaseAllowance(
        address holder,
        address spender,
        uint256 amount
    ) internal {
        uint256 allowance = _allowance(holder, spender);

        if (amount > allowance) revert ERC20Base__InsufficientAllowance();

        unchecked {
            _approve(holder, spender, allowance - amount);
        }
    }

    /**
     * @notice mint tokens for given account
     * @param account recipient of minted tokens
     * @param amount quantity of tokens minted
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__MintToZeroAddress();

        _beforeTokenTransfer(address(0), account, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        l.totalSupply += amount;
        l.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice burn tokens held by given account
     * @param account holder of burned tokens
     * @param amount quantity of tokens burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__BurnFromZeroAddress();

        _beforeTokenTransfer(account, address(0), amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 balance = l.balances[account];
        if (amount > balance) revert ERC20Base__BurnExceedsBalance();
        unchecked {
            l.balances[account] = balance - amount;
        }
        l.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     * @return success status (always true; otherwise function should revert)
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        if (holder == address(0)) revert ERC20Base__TransferFromZeroAddress();
        if (recipient == address(0)) revert ERC20Base__TransferToZeroAddress();

        _beforeTokenTransfer(holder, recipient, amount);

        ERC20BaseStorage.Layout storage l = ERC20BaseStorage.layout();
        uint256 holderBalance = l.balances[holder];
        if (amount > holderBalance) revert ERC20Base__TransferExceedsBalance();
        unchecked {
            l.balances[holder] = holderBalance - amount;
        }
        l.balances[recipient] += amount;

        emit Transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function _transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        _decreaseAllowance(holder, msg.sender, amount);

        _transfer(holder, recipient, amount);

        return true;
    }

    /**
     * @notice ERC20 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param amount quantity of tokens transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20BaseStorage {
    struct Layout {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Extended } from './IERC20Extended.sol';
import { ERC20ExtendedInternal } from './ERC20ExtendedInternal.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20Extended is IERC20Extended, ERC20ExtendedInternal {
    /**
     * @inheritdoc IERC20Extended
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        return _increaseAllowance(spender, amount);
    }

    /**
     * @inheritdoc IERC20Extended
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool) {
        return _decreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC20BaseInternal, ERC20BaseStorage } from '../base/ERC20Base.sol';
import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 safe approval extensions
 * @dev mitigations for transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
 */
abstract contract ERC20ExtendedInternal is
    ERC20BaseInternal,
    IERC20ExtendedInternal
{
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function _increaseAllowance(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        uint256 allowance = _allowance(msg.sender, spender);

        unchecked {
            if (allowance > allowance + amount)
                revert ERC20Extended__ExcessiveAllowance();

            return _approve(msg.sender, spender, allowance + amount);
        }
    }

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function _decreaseAllowance(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        _decreaseAllowance(msg.sender, spender, amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from './IERC20Metadata.sol';
import { ERC20MetadataInternal } from './ERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata extensions
 */
abstract contract ERC20Metadata is IERC20Metadata, ERC20MetadataInternal {
    /**
     * @inheritdoc IERC20Metadata
     */
    function name() external view returns (string memory) {
        return _name();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function symbol() external view returns (string memory) {
        return _symbol();
    }

    /**
     * @inheritdoc IERC20Metadata
     */
    function decimals() external view returns (uint8) {
        return _decimals();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';
import { ERC20MetadataStorage } from './ERC20MetadataStorage.sol';

/**
 * @title ERC20Metadata internal functions
 */
abstract contract ERC20MetadataInternal is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function _name() internal view virtual returns (string memory) {
        return ERC20MetadataStorage.layout().name;
    }

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function _symbol() internal view virtual returns (string memory) {
        return ERC20MetadataStorage.layout().symbol;
    }

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function _decimals() internal view virtual returns (uint8) {
        return ERC20MetadataStorage.layout().decimals;
    }

    function _setName(string memory name) internal virtual {
        ERC20MetadataStorage.layout().name = name;
    }

    function _setSymbol(string memory symbol) internal virtual {
        ERC20MetadataStorage.layout().symbol = symbol;
    }

    function _setDecimals(uint8 decimals) internal virtual {
        ERC20MetadataStorage.layout().decimals = decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20MetadataStorage {
    struct Layout {
        string name;
        string symbol;
        uint8 decimals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Metadata');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { ERC20Base } from '../base/ERC20Base.sol';
import { ERC20Metadata } from '../metadata/ERC20Metadata.sol';
import { ERC20PermitInternal } from './ERC20PermitInternal.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20Permit } from './IERC20Permit.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20Permit is IERC20Permit, ERC20PermitInternal {
    /**
     * @inheritdoc IERC2612
     */
    function DOMAIN_SEPARATOR()
        external
        view
        returns (bytes32 domainSeparator)
    {
        return _DOMAIN_SEPARATOR();
    }

    /**
     * @inheritdoc IERC2612
     */
    function nonces(address owner) public view returns (uint256) {
        return _nonces(owner);
    }

    /**
     * @inheritdoc IERC2612
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        _permit(owner, spender, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { ECDSA } from '../../../cryptography/ECDSA.sol';
import { ERC20BaseInternal } from '../base/ERC20BaseInternal.sol';
import { ERC20MetadataInternal } from '../metadata/ERC20MetadataInternal.sol';
import { ERC20PermitStorage } from './ERC20PermitStorage.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

/**
 * @title ERC20 extension with support for ERC2612 permits
 * @dev derived from https://github.com/soliditylabs/ERC20-Permit (MIT license)
 */
abstract contract ERC20PermitInternal is
    ERC20BaseInternal,
    ERC20MetadataInternal,
    IERC20PermitInternal
{
    using ECDSA for bytes32;

    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function _DOMAIN_SEPARATOR()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        domainSeparator = ERC20PermitStorage.layout().domainSeparators[
            _chainId()
        ];

        if (domainSeparator == 0x00) {
            domainSeparator = _calculateDomainSeparator();
        }
    }

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function _nonces(address owner) internal view returns (uint256) {
        return ERC20PermitStorage.layout().nonces[owner];
    }

    /**
     * @notice calculate unique EIP-712 domain separator
     * @return domainSeparator domain separator
     */
    function _calculateDomainSeparator()
        internal
        view
        returns (bytes32 domainSeparator)
    {
        // no need for assembly, running very rarely
        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes(_name())), // ERC-20 Name
                keccak256(bytes('1')), // Version
                _chainId(),
                address(this)
            )
        );
    }

    /**
     * @notice get the current chain ID
     * @return chainId chain ID
     */
    function _chainId() private view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     * @dev If https://eips.ethereum.org/EIPS/eip-1344[ChainID] ever changes, the
     * EIP712 Domain Separator is automatically recalculated.
     */
    function _permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual {
        if (block.timestamp > deadline) revert ERC20Permit__ExpiredDeadline();

        // Assembly for more efficiently computing:
        // bytes32 hashStruct = keccak256(
        //   abi.encode(
        //     _PERMIT_TYPEHASH,
        //     owner,
        //     spender,
        //     amount,
        //     _nonces[owner].current(),
        //     deadline
        //   )
        // );

        ERC20PermitStorage.Layout storage l = ERC20PermitStorage.layout();

        bytes32 hashStruct;
        uint256 nonce = l.nonces[owner];

        assembly {
            // Load free memory pointer
            let pointer := mload(64)

            // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
            mstore(
                pointer,
                0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9
            )
            mstore(add(pointer, 32), owner)
            mstore(add(pointer, 64), spender)
            mstore(add(pointer, 96), amount)
            mstore(add(pointer, 128), nonce)
            mstore(add(pointer, 160), deadline)

            hashStruct := keccak256(pointer, 192)
        }

        bytes32 domainSeparator = l.domainSeparators[_chainId()];

        if (domainSeparator == 0x00) {
            domainSeparator = _calculateDomainSeparator();
            l.domainSeparators[_chainId()] = domainSeparator;
        }

        // Assembly for more efficient computing:
        // bytes32 hash = keccak256(
        //   abi.encodePacked(uint16(0x1901), domainSeparator, hashStruct)
        // );

        bytes32 hash;

        assembly {
            // Load free memory pointer
            let pointer := mload(64)

            mstore(
                pointer,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(pointer, 2), domainSeparator) // EIP712 domain hash
            mstore(add(pointer, 34), hashStruct) // Hash of struct

            hash := keccak256(pointer, 66)
        }

        address signer = hash.recover(v, r, s);

        if (signer != owner) revert ERC20Permit__InvalidSignature();

        l.nonces[owner]++;
        _approve(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC20PermitStorage {
    struct Layout {
        mapping(address => uint256) nonces;
        // Mapping of ChainID to domain separators. This is a very gas efficient way
        // to not recalculate the domain separator on every call, while still
        // automatically detecting ChainID changes.
        mapping(uint256 => bytes32) domainSeparators;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Permit');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ISolidStateERC20 } from './ISolidStateERC20.sol';
import { ERC20Base } from './base/ERC20Base.sol';
import { ERC20Extended } from './extended/ERC20Extended.sol';
import { ERC20Metadata } from './metadata/ERC20Metadata.sol';
import { ERC20Permit } from './permit/ERC20Permit.sol';

/**
 * @title SolidState ERC20 implementation, including recommended extensions
 */
abstract contract SolidStateERC20 is
    ISolidStateERC20,
    ERC20Base,
    ERC20Extended,
    ERC20Metadata,
    ERC20Permit
{

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library Math {
    /**
     * @notice calculate the absolute value of a number
     * @param a number whose absoluve value to calculate
     * @return absolute value
     */
    function abs(int256 a) internal pure returns (uint256) {
        return uint256(a < 0 ? -a : a);
    }

    /**
     * @notice select the greater of two numbers
     * @param a first number
     * @param b second number
     * @return greater number
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @notice select the lesser of two numbers
     * @param a first number
     * @param b second number
     * @return lesser number
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    /**
     * @notice calculate the average of two numbers, rounded down
     * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
     * @param a first number
     * @param b second number
     * @return mean value
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return (a & b) + ((a ^ b) >> 1);
        }
    }

    /**
     * @notice estimate square root of number
     * @dev uses Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param x input number
     * @return y square root
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) >> 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../interfaces/IERC20.sol';
import { AddressUtils } from './AddressUtils.sol';

/**
 * @title Safe ERC20 interaction library
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library SafeERC20 {
    using AddressUtils for address;

    error SafeERC20__ApproveFromNonZeroToNonZero();
    error SafeERC20__DecreaseAllowanceBelowZero();
    error SafeERC20__OperationFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev safeApprove (like approve) should only be called when setting an initial allowance or when resetting it to zero; otherwise prefer safeIncreaseAllowance and safeDecreaseAllowance
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if ((value != 0) && (token.allowance(address(this), spender) != 0))
            revert SafeERC20__ApproveFromNonZeroToNonZero();

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            if (oldAllowance < value)
                revert SafeERC20__DecreaseAllowanceBelowZero();
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @notice send transaction data and check validity of return value, if present
     * @param token ERC20 token interface
     * @param data transaction data
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );

        if (returndata.length > 0) {
            if (!abi.decode(returndata, (bool)))
                revert SafeERC20__OperationFailed();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x4) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Premia Exchange Helper
 * @dev deployed standalone and referenced by internal functions
 * @dev do NOT set approval to this contract!
 */
interface IExchangeHelper {
    /**
     * @notice perform arbitrary swap transaction
     * @param sourceToken source token to pull into this address
     * @param targetToken target token to buy
     * @param sourceTokenAmount amount of source token to start the trade
     * @param callee exchange address to call to execute the trade.
     * @param allowanceTarget address for which to set allowance for the trade
     * @param data calldata to execute the trade
     * @param refundAddress address that un-used source token goes to
     * @return amountOut quantity of targetToken yielded by swap
     */
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 sourceTokenAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ILayerZeroUserApplicationConfig} from "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    /**
     * @notice send a LayerZero message to the specified address at a LayerZero endpoint.
     * @param dstChainId - the destination chain identifier
     * @param destination - the address on destination chain (in bytes). address length/format may vary by chains
     * @param payload - a custom bytes payload to send to the destination contract
     * @param refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
     * @param zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
     * @param adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
     */
    function send(
        uint16 dstChainId,
        bytes calldata destination,
        bytes calldata payload,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /**
     * @notice used by the messaging library to publish verified payload
     * @param srcChainId - the source chain identifier
     * @param srcAddress - the source contract (as bytes) at the source chain
     * @param dstAddress - the address on destination chain
     * @param nonce - the unbound message ordering nonce
     * @param gasLimit - the gas limit for external contract execution
     * @param payload - verified payload to send to the destination contract
     */
    function receivePayload(
        uint16 srcChainId,
        bytes calldata srcAddress,
        address dstAddress,
        uint64 nonce,
        uint256 gasLimit,
        bytes calldata payload
    ) external;

    /*
     * @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
     * @param srcChainId - the source chain identifier
     * @param srcAddress - the source chain contract address
     */
    function getInboundNonce(
        uint16 srcChainId,
        bytes calldata srcAddress
    ) external view returns (uint64);

    /*
     * @notice get the outboundNonce from this source chain which, consequently, is always an EVM
     * @param srcAddress - the source chain contract address
     */
    function getOutboundNonce(
        uint16 dstChainId,
        address srcAddress
    ) external view returns (uint64);

    /*
     * @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
     * @param dstChainId - the destination chain identifier
     * @param userApplication - the user app address on this EVM chain
     * @param payload - the custom message to send over LayerZero
     * @param payInZRO - if false, user app pays the protocol fee in native token
     * @param adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
     */
    function estimateFees(
        uint16 dstChainId,
        address userApplication,
        bytes calldata payload,
        bool payInZRO,
        bytes calldata adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /*
     * @notice get this Endpoint's immutable source identifier
     */
    function getChainId() external view returns (uint16);

    /*
     * @notice the interface to retry failed message on this Endpoint destination
     * @param srcChainId - the source chain identifier
     * @param srcAddress - the source chain contract address
     * @param payload - the payload to be retried
     */
    function retryPayload(
        uint16 srcChainId,
        bytes calldata srcAddress,
        bytes calldata payload
    ) external;

    /*
     * @notice query if any STORED payload (message blocking) at the endpoint.
     * @param srcChainId - the source chain identifier
     * @param srcAddress - the source chain contract address
     */
    function hasStoredPayload(
        uint16 srcChainId,
        bytes calldata srcAddress
    ) external view returns (bool);

    /*
     * @notice query if the libraryAddress is valid for sending msgs.
     * @param userApplication - the user app address on this EVM chain
     */
    function getSendLibraryAddress(
        address userApplication
    ) external view returns (address);

    /*
     * @notice query if the libraryAddress is valid for receiving msgs.
     * @param userApplication - the user app address on this EVM chain
     */
    function getReceiveLibraryAddress(
        address userApplication
    ) external view returns (address);

    /*
     * @notice query if the non-reentrancy guard for send() is on
     * @return true if the guard is on. false otherwise
     */
    function isSendingPayload() external view returns (bool);

    /*
     * @notice query if the non-reentrancy guard for receive() is on
     * @return true if the guard is on. false otherwise
     */
    function isReceivingPayload() external view returns (bool);

    /*
     * @notice get the configuration of the LayerZero messaging library of the specified version
     * @param version - messaging library version
     * @param chainId - the chainId for the pending config change
     * @param userApplication - the contract address of the user application
     * @param configType - type of configuration. every messaging library has its own convention.
     */
    function getConfig(
        uint16 version,
        uint16 chainId,
        address userApplication,
        uint256 configType
    ) external view returns (bytes memory);

    /*
     * @notice get the send() LayerZero messaging library version
     * @param userApplication - the contract address of the user application
     */
    function getSendVersion(
        address userApplication
    ) external view returns (uint16);

    /*
     * @notice get the lzReceive() LayerZero messaging library version
     * @param userApplication - the contract address of the user application
     */
    function getReceiveVersion(
        address userApplication
    ) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    /*
     * @notice LayerZero endpoint will invoke this function to deliver the message on the destination
     * @param srcChainId - the source endpoint identifier
     * @param srcAddress - the source sending contract address from the source chain
     * @param nonce - the ordered message nonce
     * @param payload - the signed payload is the UA bytes has encoded to be sent
     */
    function lzReceive(
        uint16 srcChainId,
        bytes calldata srcAddress,
        uint64 nonce,
        bytes calldata payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroUserApplicationConfig {
    /*
     * @notice set the configuration of the LayerZero messaging library of the specified version
     * @param version - messaging library version
     * @param chainId - the chainId for the pending config change
     * @param configType - type of configuration. every messaging library has its own convention.
     * @param config - configuration in the bytes. can encode arbitrary content.
     */
    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external;

    /*
     * @notice set the send() LayerZero messaging library version to version
     * @param version - new messaging library version
     */
    function setSendVersion(uint16 version) external;

    /*
     * @notice set the lzReceive() LayerZero messaging library version to version
     * @param version - new messaging library version
     */
    function setReceiveVersion(uint16 version) external;

    /*
     * @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
     * @param srcChainId - the chainId of the source chain
     * @param srcAddress - the contract address of the source contract at the source chain
     */
    function forceResumeReceive(
        uint16 srcChainId,
        bytes calldata srcAddress
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import {ILayerZeroReceiver} from "../interfaces/ILayerZeroReceiver.sol";
import {ILayerZeroUserApplicationConfig} from "../interfaces/ILayerZeroUserApplicationConfig.sol";
import {ILayerZeroEndpoint} from "../interfaces/ILayerZeroEndpoint.sol";
import {LzAppStorage} from "./LzAppStorage.sol";
import {BytesLib} from "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
    OwnableInternal,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using BytesLib for bytes;

    ILayerZeroEndpoint public immutable lzEndpoint;

    //    event SetPrecrime(address precrime);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);

    error LzApp__InvalidEndpointCaller();
    error LzApp__InvalidSource();
    error LzApp__NotTrustedSource();
    error LzApp__NoTrustedPathRecord();

    constructor(address endpoint) {
        lzEndpoint = ILayerZeroEndpoint(endpoint);
    }

    /**
     * @inheritdoc ILayerZeroReceiver
     */
    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public virtual {
        // lzReceive must be called by the endpoint for security
        if (msg.sender != address(lzEndpoint))
            revert LzApp__InvalidEndpointCaller();

        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        if (!_isTrustedRemote(srcChainId, srcAddress))
            revert LzApp__InvalidSource();

        _blockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual;

    function _lzSend(
        uint16 dstChainId,
        bytes memory payload,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams,
        uint256 nativeFee
    ) internal virtual {
        bytes memory trustedRemote = LzAppStorage.layout().trustedRemote[
            dstChainId
        ];
        if (trustedRemote.length == 0) revert LzApp__NotTrustedSource();
        lzEndpoint.send{value: nativeFee}(
            dstChainId,
            trustedRemote,
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 version,
        uint16 chainId,
        address,
        uint256 configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(version, chainId, address(this), configType);
    }

    /**
     * @inheritdoc ILayerZeroUserApplicationConfig
     */
    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external onlyOwner {
        lzEndpoint.setConfig(version, chainId, configType, config);
    }

    /**
     * @inheritdoc ILayerZeroUserApplicationConfig
     */
    function setSendVersion(uint16 version) external onlyOwner {
        lzEndpoint.setSendVersion(version);
    }

    /**
     * @inheritdoc ILayerZeroUserApplicationConfig
     */
    function setReceiveVersion(uint16 version) external onlyOwner {
        lzEndpoint.setReceiveVersion(version);
    }

    /**
     * @inheritdoc ILayerZeroUserApplicationConfig
     */
    function forceResumeReceive(
        uint16 srcChainId,
        bytes calldata srcAddress
    ) external onlyOwner {
        lzEndpoint.forceResumeReceive(srcChainId, srcAddress);
    }

    function setTrustedRemoteAddress(
        uint16 remoteChainId,
        bytes calldata remoteAddress
    ) external onlyOwner {
        LzAppStorage.layout().trustedRemote[remoteChainId] = abi.encodePacked(
            remoteAddress,
            address(this)
        );
        emit SetTrustedRemoteAddress(remoteChainId, remoteAddress);
    }

    function getTrustedRemoteAddress(
        uint16 _remoteChainId
    ) external view returns (bytes memory) {
        bytes memory path = LzAppStorage.layout().trustedRemote[_remoteChainId];
        if (path.length == 0) revert LzApp__NoTrustedPathRecord();
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    //    function setPrecrime(address _precrime) external onlyOwner {
    //        LzAppStorage.layout().precrime = _precrime;
    //        emit SetPrecrime(_precrime);
    //    }

    //--------------------------- VIEW FUNCTION ----------------------------------------

    function isTrustedRemote(
        uint16 srcChainId,
        bytes memory srcAddress
    ) external view returns (bool) {
        return _isTrustedRemote(srcChainId, srcAddress);
    }

    function _isTrustedRemote(
        uint16 srcChainId,
        bytes memory srcAddress
    ) internal view returns (bool) {
        bytes memory trustedRemote = LzAppStorage.layout().trustedRemote[
            srcChainId
        ];

        return
            srcAddress.length == trustedRemote.length &&
            trustedRemote.length > 0 &&
            keccak256(trustedRemote) == keccak256(srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LzAppStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.LzApp");

    struct Layout {
        mapping(uint16 => bytes) trustedRemote;
        address precrime;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {LzApp} from "./LzApp.sol";
import {NonblockingLzAppStorage} from "./NonblockingLzAppStorage.sol";
import {ExcessivelySafeCall} from "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    error NonblockingLzApp__CallerNotLzApp();
    error NonblockingLzApp__InvalidPayload();
    error NonblockingLzApp__NoStoredMessage();

    constructor(address endpoint) LzApp(endpoint) {}

    event MessageFailed(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        bytes payload,
        bytes reason
    );
    event RetryMessageSuccess(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        bytes32 payloadHash
    );

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(
                this.nonblockingLzReceive.selector,
                srcChainId,
                srcAddress,
                nonce,
                payload
            )
        );
        // try-catch all errors/exceptions
        if (!success) {
            NonblockingLzAppStorage.layout().failedMessages[srcChainId][
                srcAddress
            ][nonce] = keccak256(payload);
            emit MessageFailed(srcChainId, srcAddress, nonce, payload, reason);
        }
    }

    function nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public virtual {
        // only internal transaction
        if (msg.sender != address(this))
            revert NonblockingLzApp__CallerNotLzApp();
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    // override this function
    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual;

    function retryMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) public payable virtual {
        NonblockingLzAppStorage.Layout storage l = NonblockingLzAppStorage
            .layout();

        // assert there is message to retry
        bytes32 payloadHash = l.failedMessages[srcChainId][srcAddress][nonce];

        if (payloadHash == bytes32(0))
            revert NonblockingLzApp__NoStoredMessage();

        if (keccak256(payload) != payloadHash)
            revert NonblockingLzApp__InvalidPayload();

        // clear the stored message
        delete l.failedMessages[srcChainId][srcAddress][nonce];
        // execute the message. revert if it fails again
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
        emit RetryMessageSuccess(srcChainId, srcAddress, nonce, payloadHash);
    }

    function failedMessages(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce
    ) external view returns (bytes32) {
        return
            NonblockingLzAppStorage.layout().failedMessages[srcChainId][
                srcAddress
            ][nonce];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library NonblockingLzAppStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.NonblockingLzApp");

    struct Layout {
        mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) failedMessages;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IOFTCore} from "./IOFTCore.sol";
import {ISolidStateERC20} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, ISolidStateERC20 {
    error OFT_InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `tokenId` to (`dstChainId`, `toAddress`)
     * dstChainId - L0 defined chain id to send tokens too
     * toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * amount - amount of the tokens to transfer
     * useZro - indicates to use zro to pay L0 fees
     * adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        bool useZro,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send `amount` amount of token to (`dstChainId`, `toAddress`) from `from`
     * `from` the owner of token
     * `dstChainId` the destination chain identifier
     * `toAddress` can be any size depending on the `dstChainId`.
     * `amount` the quantity of tokens in wei
     * `refundAddress` the address LayerZero refunds if too much message fee is sent
     * `zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);

    /**
     * @dev Emitted when `amount` tokens are moved from the `sender` to (`dstChainId`, `toAddress`)
     * `nonce` is the outbound nonce
     */
    event SendToChain(
        address indexed sender,
        uint16 indexed dstChainId,
        bytes indexed toAddress,
        uint256 amount
    );

    /**
     * @dev Emitted when `amount` tokens are received from `srcChainId` into the `toAddress` on the local chain.
     * `nonce` is the inbound nonce.
     */
    event ReceiveFromChain(
        uint16 indexed srcChainId,
        bytes indexed srcAddress,
        address indexed toAddress,
        uint256 amount
    );

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20Base, ERC20BaseStorage} from "@solidstate/contracts/token/ERC20/base/ERC20Base.sol";
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

import {OFTCore} from "./OFTCore.sol";
import {IOFT} from "./IOFT.sol";

// override decimal() function is needed
contract OFT is OFTCore, SolidStateERC20, IOFT {
    constructor(address lzEndpoint) OFTCore(lzEndpoint) {}

    function circulatingSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _totalSupply();
    }

    function _debitFrom(
        address from,
        uint16,
        bytes memory,
        uint256 amount
    ) internal virtual override {
        address spender = msg.sender;

        if (from != spender) {
            unchecked {
                mapping(address => uint256)
                    storage allowances = ERC20BaseStorage.layout().allowances[
                        spender
                    ];

                uint256 allowance = allowances[spender];
                if (amount > allowance) revert OFT_InsufficientAllowance();

                _approve(
                    from,
                    spender,
                    allowances[spender] = allowance - amount
                );
            }
        }

        _burn(from, amount);
    }

    function _creditTo(
        uint16,
        address toAddress,
        uint256 amount
    ) internal virtual override {
        _mint(toAddress, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {NonblockingLzApp} from "../../lzApp/NonblockingLzApp.sol";
import {IOFTCore} from "./IOFTCore.sol";
import {ERC165Base, IERC165} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {BytesLib} from "../../util/BytesLib.sol";

abstract contract OFTCore is NonblockingLzApp, ERC165Base, IOFTCore {
    using BytesLib for bytes;

    // packet type
    uint16 public constant PT_SEND = 0;

    constructor(address lzEndpoint) NonblockingLzApp(lzEndpoint) {}

    function estimateSendFee(
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        bool useZro,
        bytes memory adapterParams
    ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(
            PT_SEND,
            abi.encodePacked(msg.sender),
            toAddress,
            amount
        );
        return
            lzEndpoint.estimateFees(
                dstChainId,
                address(this),
                payload,
                useZro,
                adapterParams
            );
    }

    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) public payable virtual override {
        _send(
            from,
            dstChainId,
            toAddress,
            amount,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual override {
        uint16 packetType;
        assembly {
            packetType := mload(add(payload, 32))
        }

        if (packetType == PT_SEND) {
            _sendAck(srcChainId, srcAddress, nonce, payload);
        } else {
            revert("OFTCore: unknown packet type");
        }
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) internal virtual {
        _debitFrom(from, dstChainId, toAddress, amount);

        bytes memory payload = abi.encode(
            PT_SEND,
            abi.encodePacked(from),
            toAddress,
            amount
        );

        _lzSend(
            dstChainId,
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams,
            msg.value
        );

        emit SendToChain(from, dstChainId, toAddress, amount);
    }

    function _sendAck(
        uint16 srcChainId,
        bytes memory,
        uint64,
        bytes memory payload
    ) internal virtual {
        (, bytes memory from, bytes memory toAddressBytes, uint256 amount) = abi
            .decode(payload, (uint16, bytes, bytes, uint256));

        address to = toAddressBytes.toAddress(0);

        _creditTo(srcChainId, to, amount);
        emit ReceiveFromChain(srcChainId, from, to, amount);
    }

    function _debitFrom(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount
    ) internal virtual;

    function _creditTo(
        uint16 srcChainId,
        address toAddress,
        uint256 amount
    ) internal virtual;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    error BytesLib__Overflow();
    error BytesLib__OutOfBounds();

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    ) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert BytesLib__Overflow();
        if (_bytes.length < _start + _length) revert BytesLib__OutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        if (_bytes.length < _start + 20) revert BytesLib__OutOfBounds();
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint8) {
        if (_bytes.length < _start + 1) revert BytesLib__OutOfBounds();
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint16) {
        if (_bytes.length < _start + 2) revert BytesLib__OutOfBounds();
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint32) {
        if (_bytes.length < _start + 4) revert BytesLib__OutOfBounds();
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint64) {
        if (_bytes.length < _start + 8) revert BytesLib__OutOfBounds();
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint96) {
        if (_bytes.length < _start + 12) revert BytesLib__OutOfBounds();
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint128) {
        if (_bytes.length < _start + 16) revert BytesLib__OutOfBounds();
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint256) {
        if (_bytes.length < _start + 32) revert BytesLib__OutOfBounds();
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (bytes32) {
        if (_bytes.length < _start + 32) revert BytesLib__OutOfBounds();
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    ) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(
        bytes4 _newSelector,
        bytes memory _buf
    ) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {IOFT} from "../layerZero/token/oft/IOFT.sol";

import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

// IERC20Metadata inheritance not possible due to linearization issue
interface IPremiaStaking is IERC2612, IOFT {
    error PremiaStaking__CantTransfer();
    error PremiaStaking__ExcessiveStakePeriod();
    error PremiaStaking__InsufficientSwapOutput();
    error PremiaStaking__NoPendingWithdrawal();
    error PremiaStaking__NotEnoughLiquidity();
    error PremiaStaking__PeriodTooShort();
    error PremiaStaking__StakeLocked();
    error PremiaStaking__StakeNotLocked();
    error PremiaStaking__WithdrawalStillPending();

    event Stake(
        address indexed user,
        uint256 amount,
        uint64 stakePeriod,
        uint64 lockedUntil
    );

    event Unstake(
        address indexed user,
        uint256 amount,
        uint256 fee,
        uint256 startDate
    );

    event Harvest(address indexed user, uint256 amount);

    event EarlyUnstakeRewardCollected(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event RewardsAdded(uint256 amount);

    struct StakeLevel {
        uint256 amount; // Amount to stake
        uint256 discountBPS; // Discount when amount is reached
    }

    struct SwapArgs {
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    event BridgeLock(
        address indexed user,
        uint64 stakePeriod,
        uint64 lockedUntil
    );

    event UpdateLock(
        address indexed user,
        uint64 oldStakePeriod,
        uint64 newStakePeriod
    );

    /**
     * @notice Returns the reward token address
     * @return The reward token address
     */
    function getRewardToken() external view returns (address);

    /**
     * @notice add premia tokens as available tokens to be distributed as rewards
     * @param amount amount of premia tokens to add as rewards
     */
    function addRewards(uint256 amount) external;

    /**
     * @notice get amount of tokens that have not yet been distributed as rewards
     * @return rewards amount of tokens not yet distributed as rewards
     * @return unstakeRewards amount of PREMIA not yet claimed from early unstake fees
     */
    function getAvailableRewards()
        external
        view
        returns (uint256 rewards, uint256 unstakeRewards);

    /**
     * @notice get pending amount of tokens to be distributed as rewards to stakers
     * @return amount of tokens pending to be distributed as rewards
     */
    function getPendingRewards() external view returns (uint256);

    /**
     * @notice get pending withdrawal data of a user
     * @return amount pending withdrawal amount
     * @return startDate start timestamp of withdrawal
     * @return unlockDate timestamp at which withdrawal becomes available
     */
    function getPendingWithdrawal(
        address user
    )
        external
        view
        returns (uint256 amount, uint256 startDate, uint256 unlockDate);

    /**
     * @notice get the amount of PREMIA available for withdrawal
     * @return amount of PREMIA available for withdrawal
     */
    function getAvailablePremiaAmount() external view returns (uint256);

    /**
     * @notice Stake using IERC2612 permit
     * @param amount The amount of xPremia to stake
     * @param period The lockup period (in seconds)
     * @param deadline Deadline after which permit will fail
     * @param v V
     * @param r R
     * @param s S
     */
    function stakeWithPermit(
        uint256 amount,
        uint64 period,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Lockup xPremia for protocol fee discounts
     *          Longer period of locking will apply a multiplier on the amount staked, in the fee discount calculation
     * @param amount The amount of xPremia to stake
     * @param period The lockup period (in seconds)
     */
    function stake(uint256 amount, uint64 period) external;

    /**
     * @notice update vxPremia lock
     * @param period The new lockup period (in seconds)
     */
    function updateLock(uint64 period) external;

    /**
     * @notice harvest rewards, convert to PREMIA using exchange helper, and stake
     * @param s swap arguments
     * @param stakePeriod The lockup period (in seconds)
     */
    function harvestAndStake(
        IPremiaStaking.SwapArgs memory s,
        uint64 stakePeriod
    ) external;

    /**
     * @notice Harvest rewards directly to user wallet
     */
    function harvest() external;

    /**
     * @notice Get pending rewards amount, including pending pool update
     * @param user User for which to calculate pending rewards
     * @return reward amount of pending rewards from protocol fees (in REWARD_TOKEN)
     * @return unstakeReward amount of pending rewards from early unstake fees (in PREMIA)
     */
    function getPendingUserRewards(
        address user
    ) external view returns (uint256 reward, uint256 unstakeReward);

    /**
     * @notice unstake tokens before end of the lock period, for a fee
     * @param amount the amount of vxPremia to unstake
     */
    function earlyUnstake(uint256 amount) external;

    /**
     * @notice get early unstake fee for given user
     * @param user address of the user
     * @return feePercentage % fee to pay for early unstake (1e4 = 100%)
     */
    function getEarlyUnstakeFeeBPS(
        address user
    ) external view returns (uint256 feePercentage);

    /**
     * @notice Initiate the withdrawal process by burning xPremia, starting the delay period
     * @param amount quantity of xPremia to unstake
     */
    function startWithdraw(uint256 amount) external;

    /**
     * @notice Withdraw underlying premia
     */
    function withdraw() external;

    //////////
    // View //
    //////////

    /**
     * Calculate the stake amount of a user, after applying the bonus from the lockup period chosen
     * @param user The user from which to query the stake amount
     * @return The user stake amount after applying the bonus
     */
    function getUserPower(address user) external view returns (uint256);

    /**
     * Return the total power across all users (applying the bonus from lockup period chosen)
     * @return The total power across all users
     */
    function getTotalPower() external view returns (uint256);

    /**
     * @notice Calculate the % of fee discount for user, based on his stake
     * @param user The _user for which the discount is for
     * @return Percentage of protocol fee discount (in basis point)
     *         Ex : 1000 = 10% fee discount
     */
    function getDiscountBPS(address user) external view returns (uint256);

    /**
     * @notice Get stake levels
     * @return Stake levels
     *         Ex : 2500 = -25%
     */
    function getStakeLevels() external returns (StakeLevel[] memory);

    /**
     * @notice Get stake period multiplier
     * @param period The duration (in seconds) for which tokens are locked
     * @return The multiplier for this staking period
     *         Ex : 20000 = x2
     */
    function getStakePeriodMultiplierBPS(
        uint256 period
    ) external returns (uint256);

    /**
     * @notice Get staking infos of a user
     * @param user The user address for which to get staking infos
     * @return The staking infos of the user
     */
    function getUserInfo(
        address user
    ) external view returns (PremiaStakingStorage.UserInfo memory);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {VxPremiaStorage} from "./VxPremiaStorage.sol";
import {IPremiaStaking} from "./IPremiaStaking.sol";

interface IVxPremia is IPremiaStaking {
    error VxPremia__NotEnoughVotingPower();

    event AddVote(
        address indexed voter,
        VxPremiaStorage.VoteVersion indexed version,
        bytes target,
        uint256 amount
    );
    event RemoveVote(
        address indexed voter,
        VxPremiaStorage.VoteVersion indexed version,
        bytes target,
        uint256 amount
    );

    /**
     * @notice get total votes for specific pools
     * @param version version of target (used to know how to decode data)
     * @param target ABI encoded target of the votes
     * @return total votes for specific pool
     */
    function getPoolVotes(
        VxPremiaStorage.VoteVersion version,
        bytes memory target
    ) external view returns (uint256);

    /**
     * @notice get votes of user
     * @param user user from which to get votes
     * @return votes of user
     */
    function getUserVotes(
        address user
    ) external view returns (VxPremiaStorage.Vote[] memory);

    /**
     * @notice add or remove votes, in the limit of the user voting power
     * @param votes votes to cast
     */
    function castVotes(VxPremiaStorage.Vote[] memory votes) external;
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";
import {Math} from "@solidstate/contracts/utils/Math.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import {SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

import {IExchangeHelper} from "../interfaces/IExchangeHelper.sol";
import {IPremiaStaking} from "./IPremiaStaking.sol";
import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {OFT} from "../layerZero/token/oft/OFT.sol";
import {OFTCore} from "../layerZero/token/oft/OFTCore.sol";
import {IOFTCore} from "../layerZero/token/oft/IOFTCore.sol";
import {BytesLib} from "../layerZero/util/BytesLib.sol";

contract PremiaStaking is IPremiaStaking, OFT {
    using SafeERC20 for IERC20;
    using ABDKMath64x64 for int128;
    using AddressUtils for address;
    using BytesLib for bytes;

    address internal immutable PREMIA;
    address internal immutable REWARD_TOKEN;
    address internal immutable EXCHANGE_HELPER;

    int128 internal constant ONE_64x64 = 0x10000000000000000;
    int128 internal constant DECAY_RATE_64x64 = 0x487a423b63e; // 2.7e-7 -> Distribute around half of the current balance over a month
    uint256 internal constant INVERSE_BASIS_POINT = 1e4;
    uint64 internal constant MAX_PERIOD = 4 * 365 days;
    uint256 internal constant ACC_REWARD_PRECISION = 1e30;
    uint256 internal constant MAX_CONTRACT_DISCOUNT = 3000; // -30%
    uint256 internal constant WITHDRAWAL_DELAY = 10 days;

    struct UpdateArgsInternal {
        address user;
        uint256 balance;
        uint256 oldPower;
        uint256 newPower;
        uint256 reward;
        uint256 unstakeReward;
    }

    constructor(
        address lzEndpoint,
        address premia,
        address rewardToken,
        address exchangeHelper
    ) OFT(lzEndpoint) {
        PREMIA = premia;
        REWARD_TOKEN = rewardToken;
        EXCHANGE_HELPER = exchangeHelper;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (from == address(0) || to == address(0)) return;

        revert PremiaStaking__CantTransfer();
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getRewardToken() external view returns (address) {
        return REWARD_TOKEN;
    }

    function estimateSendFee(
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 amount,
        bool useZro,
        bytes memory adapterParams
    )
        public
        view
        virtual
        override(OFTCore, IOFTCore)
        returns (uint256 nativeFee, uint256 zroFee)
    {
        // Convert bytes to address
        address to;
        assembly {
            to := mload(add(toAddress, 32))
        }

        PremiaStakingStorage.UserInfo storage u = PremiaStakingStorage
            .layout()
            .userInfo[to];

        return
            lzEndpoint.estimateFees(
                dstChainId,
                address(this),
                abi.encode(PT_SEND, to, amount, u.stakePeriod, u.lockedUntil),
                useZro,
                adapterParams
            );
    }

    function _send(
        address from,
        uint16 dstChainId,
        bytes memory,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) internal virtual override {
        _updateRewards();
        _beforeUnstake(from, amount);

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[from];

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(
            l,
            u,
            from
        );

        bytes memory toAddress = abi.encodePacked(from);
        _debitFrom(from, dstChainId, toAddress, amount);

        args.newPower = _calculateUserPower(
            args.balance - amount + args.unstakeReward,
            u.stakePeriod
        );

        _updateUser(l, u, args);

        _lzSend(
            dstChainId,
            abi.encode(
                PT_SEND,
                toAddress,
                amount,
                u.stakePeriod,
                u.lockedUntil
            ),
            refundAddress,
            zroPaymentAddress,
            adapterParams,
            msg.value
        );

        emit SendToChain(from, dstChainId, toAddress, amount);
    }

    function _sendAck(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64,
        bytes memory payload
    ) internal virtual override {
        (
            ,
            bytes memory toAddressBytes,
            uint256 amount,
            uint64 stakePeriod,
            uint64 lockedUntil
        ) = abi.decode(payload, (uint16, bytes, uint256, uint64, uint64));

        address to = toAddressBytes.toAddress(0);

        _creditTo(to, amount, stakePeriod, lockedUntil, true);
        emit ReceiveFromChain(srcChainId, srcAddress, to, amount);
    }

    function _creditTo(
        address toAddress,
        uint256 amount,
        uint64 stakePeriod,
        uint64 creditLockedUntil,
        bool bridge
    ) internal {
        unchecked {
            _updateRewards();

            PremiaStakingStorage.Layout storage l = PremiaStakingStorage
                .layout();
            PremiaStakingStorage.UserInfo storage u = l.userInfo[toAddress];

            UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(
                l,
                u,
                toAddress
            );

            uint64 lockedUntil = u.lockedUntil;

            uint64 lockLeft = uint64(
                _calculateWeightedAverage(
                    creditLockedUntil > block.timestamp
                        ? creditLockedUntil - block.timestamp
                        : 0,
                    lockedUntil > block.timestamp
                        ? lockedUntil - block.timestamp
                        : 0,
                    amount + args.unstakeReward,
                    args.balance
                )
            );

            u.lockedUntil = lockedUntil = uint64(block.timestamp) + lockLeft;

            u.stakePeriod = uint64(
                _calculateWeightedAverage(
                    stakePeriod,
                    u.stakePeriod,
                    amount + args.unstakeReward,
                    args.balance
                )
            );

            args.newPower = _calculateUserPower(
                args.balance + amount + args.unstakeReward,
                u.stakePeriod
            );

            _mint(toAddress, amount);

            _updateUser(l, u, args);

            if (bridge) {
                emit BridgeLock(toAddress, u.stakePeriod, lockedUntil);
            } else {
                emit Stake(toAddress, amount, u.stakePeriod, lockedUntil);
            }
        }
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function addRewards(uint256 amount) external {
        _updateRewards();

        IERC20(REWARD_TOKEN).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        PremiaStakingStorage.layout().availableRewards += amount;

        emit RewardsAdded(amount);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getAvailableRewards()
        external
        view
        returns (uint256 rewards, uint256 unstakeRewards)
    {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        unchecked {
            rewards = l.availableRewards - _getPendingRewards();
        }
        unstakeRewards = l.availableUnstakeRewards;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getPendingRewards() external view returns (uint256) {
        return _getPendingRewards();
    }

    function _getPendingRewards() internal view returns (uint256) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        return
            l.availableRewards -
            _decay(l.availableRewards, l.lastRewardUpdate, block.timestamp);
    }

    function _updateRewards() internal {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        if (
            l.lastRewardUpdate == 0 ||
            l.totalPower == 0 ||
            l.availableRewards == 0
        ) {
            l.lastRewardUpdate = block.timestamp;
            return;
        }

        uint256 pendingRewards = _getPendingRewards();

        l.accRewardPerShare +=
            (pendingRewards * ACC_REWARD_PRECISION) /
            l.totalPower;

        unchecked {
            l.availableRewards -= pendingRewards;
        }

        l.lastRewardUpdate = block.timestamp;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function stakeWithPermit(
        uint256 amount,
        uint64 period,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC2612(PREMIA).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount, period);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function stake(uint256 amount, uint64 period) external {
        IERC20(PREMIA).safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, amount, period);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function updateLock(uint64 period) external {
        if (period > MAX_PERIOD) revert PremiaStaking__ExcessiveStakePeriod();

        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[msg.sender];

        uint64 oldPeriod = u.stakePeriod;

        if (period <= oldPeriod) revert PremiaStaking__PeriodTooShort();

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(
            l,
            u,
            msg.sender
        );

        unchecked {
            uint64 lockToAdd = period - oldPeriod;
            u.lockedUntil =
                uint64(Math.max(u.lockedUntil, block.timestamp)) +
                lockToAdd;
            u.stakePeriod = period;

            args.newPower = _calculateUserPower(
                args.balance + args.unstakeReward,
                period
            );
        }

        _updateUser(l, u, args);

        emit UpdateLock(msg.sender, oldPeriod, period);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function harvestAndStake(
        IPremiaStaking.SwapArgs memory s,
        uint64 stakePeriod
    ) external {
        uint256 amountRewardToken = _harvest(msg.sender);

        if (amountRewardToken == 0) return;

        IERC20(REWARD_TOKEN).safeTransfer(EXCHANGE_HELPER, amountRewardToken);

        uint256 amountPremia = IExchangeHelper(EXCHANGE_HELPER).swapWithToken(
            REWARD_TOKEN,
            PREMIA,
            amountRewardToken,
            s.callee,
            s.allowanceTarget,
            s.data,
            s.refundAddress
        );

        if (amountPremia < s.amountOutMin)
            revert PremiaStaking__InsufficientSwapOutput();

        _stake(msg.sender, amountPremia, stakePeriod);
    }

    function _calculateWeightedAverage(
        uint256 A,
        uint256 B,
        uint256 weightA,
        uint256 weightB
    ) internal pure returns (uint256) {
        return (A * weightA + B * weightB) / (weightA + weightB);
    }

    function _stake(
        address toAddress,
        uint256 amount,
        uint64 stakePeriod
    ) internal {
        if (stakePeriod > MAX_PERIOD)
            revert PremiaStaking__ExcessiveStakePeriod();

        unchecked {
            _creditTo(
                toAddress,
                amount,
                stakePeriod,
                uint64(block.timestamp) + stakePeriod,
                false
            );
        }
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getPendingUserRewards(
        address user
    ) external view returns (uint256 reward, uint256 unstakeReward) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[user];

        uint256 accRewardPerShare = l.accRewardPerShare;
        if (l.lastRewardUpdate > 0 && l.availableRewards > 0) {
            accRewardPerShare +=
                (_getPendingRewards() * ACC_REWARD_PRECISION) /
                l.totalPower;
        }

        uint256 power = _calculateUserPower(_balanceOf(user), u.stakePeriod);

        reward =
            u.reward +
            _calculateReward(accRewardPerShare, power, u.rewardDebt);

        unstakeReward = _calculateReward(
            l.accUnstakeRewardPerShare,
            power,
            u.unstakeRewardDebt
        );
    }

    function harvest() external {
        uint256 amount = _harvest(msg.sender);
        IERC20(REWARD_TOKEN).safeTransfer(msg.sender, amount);
    }

    function _harvest(address account) internal returns (uint256 amount) {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[account];

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(
            l,
            u,
            account
        );

        if (args.unstakeReward > 0) {
            args.newPower = _calculateUserPower(
                args.balance + args.unstakeReward,
                u.stakePeriod
            );
        } else {
            args.newPower = args.oldPower;
        }

        _updateUser(l, u, args);

        amount = u.reward;
        u.reward = 0;

        emit Harvest(account, amount);
    }

    function _updateTotalPower(
        PremiaStakingStorage.Layout storage l,
        uint256 oldUserPower,
        uint256 newUserPower
    ) internal {
        if (newUserPower > oldUserPower) {
            l.totalPower += newUserPower - oldUserPower;
        } else if (newUserPower < oldUserPower) {
            l.totalPower -= oldUserPower - newUserPower;
        }
    }

    function _beforeUnstake(address user, uint256 amount) internal virtual {}

    /**
     * @inheritdoc IPremiaStaking
     */
    function earlyUnstake(uint256 amount) external {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        _startWithdraw(
            l,
            l.userInfo[msg.sender],
            amount,
            (amount * _getEarlyUnstakeFeeBPS(msg.sender)) / INVERSE_BASIS_POINT
        );
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getEarlyUnstakeFeeBPS(
        address user
    ) external view returns (uint256 feePercentage) {
        return _getEarlyUnstakeFeeBPS(user);
    }

    function _getEarlyUnstakeFeeBPS(
        address user
    ) internal view returns (uint256 feePercentageBPS) {
        uint256 lockedUntil = PremiaStakingStorage
            .layout()
            .userInfo[user]
            .lockedUntil;

        if (lockedUntil <= block.timestamp)
            revert PremiaStaking__StakeNotLocked();

        uint256 lockLeft;

        unchecked {
            lockLeft = lockedUntil - block.timestamp;
            feePercentageBPS = (lockLeft * 2500) / 365 days; // 25% fee per year left
        }

        if (feePercentageBPS > 7500) {
            feePercentageBPS = 7500; // Capped at 75%
        }
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function startWithdraw(uint256 amount) external {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        PremiaStakingStorage.UserInfo storage u = l.userInfo[msg.sender];

        if (u.lockedUntil > block.timestamp)
            revert PremiaStaking__StakeLocked();

        _startWithdraw(l, u, amount, 0);
    }

    function _startWithdraw(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        uint256 amount,
        uint256 fee
    ) internal {
        uint256 amountMinusFee;
        unchecked {
            amountMinusFee = amount - fee;
        }

        if (_getAvailablePremiaAmount() < amountMinusFee)
            revert PremiaStaking__NotEnoughLiquidity();

        _updateRewards();
        _beforeUnstake(msg.sender, amount);

        UpdateArgsInternal memory args = _getInitialUpdateArgsInternal(
            l,
            u,
            msg.sender
        );

        _burn(msg.sender, amount);
        l.pendingWithdrawal += amountMinusFee;

        if (fee > 0) {
            l.accUnstakeRewardPerShare +=
                (fee * ACC_REWARD_PRECISION) /
                (l.totalPower - args.oldPower); // User who early unstake doesnt collect any of the fee

            l.availableUnstakeRewards += fee;
        }

        args.newPower = _calculateUserPower(
            args.balance - amount + args.unstakeReward,
            u.stakePeriod
        );

        _updateUser(l, u, args);

        l.withdrawals[msg.sender].amount += amountMinusFee;
        l.withdrawals[msg.sender].startDate = block.timestamp;

        emit Unstake(msg.sender, amount, fee, block.timestamp);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function withdraw() external {
        _updateRewards();

        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        uint256 startDate = l.withdrawals[msg.sender].startDate;

        if (startDate == 0) revert PremiaStaking__NoPendingWithdrawal();

        unchecked {
            if (block.timestamp <= startDate + WITHDRAWAL_DELAY)
                revert PremiaStaking__WithdrawalStillPending();
        }

        uint256 amount = l.withdrawals[msg.sender].amount;
        l.pendingWithdrawal -= amount;
        delete l.withdrawals[msg.sender];

        IERC20(PREMIA).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getTotalPower() external view returns (uint256) {
        return PremiaStakingStorage.layout().totalPower;
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getUserPower(address user) external view returns (uint256) {
        return
            _calculateUserPower(
                _balanceOf(user),
                PremiaStakingStorage.layout().userInfo[user].stakePeriod
            );
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getDiscountBPS(address user) external view returns (uint256) {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();

        uint256 userPower = _calculateUserPower(
            _balanceOf(user),
            l.userInfo[user].stakePeriod
        );

        // If user is a contract, we use a different formula based on % of total power owned by the contract
        if (user.isContract()) {
            // Require 50% of overall staked power for contract to have max discount
            if (userPower >= l.totalPower >> 1) {
                return MAX_CONTRACT_DISCOUNT;
            } else {
                return
                    (userPower * MAX_CONTRACT_DISCOUNT) / (l.totalPower >> 1);
            }
        }

        IPremiaStaking.StakeLevel[] memory stakeLevels = _getStakeLevels();

        uint256 length = stakeLevels.length;

        unchecked {
            for (uint256 i = 0; i < length; i++) {
                IPremiaStaking.StakeLevel memory level = stakeLevels[i];

                if (userPower < level.amount) {
                    uint256 amountPrevLevel;
                    uint256 discountPrevLevelBPS;

                    // If stake is lower, user is in this level, and we need to LERP with prev level to get discount value
                    if (i > 0) {
                        amountPrevLevel = stakeLevels[i - 1].amount;
                        discountPrevLevelBPS = stakeLevels[i - 1].discountBPS;
                    } else {
                        // If this is the first level, prev level is 0 / 0
                        amountPrevLevel = 0;
                        discountPrevLevelBPS = 0;
                    }

                    uint256 remappedDiscountBPS = level.discountBPS -
                        discountPrevLevelBPS;

                    uint256 remappedAmount = level.amount - amountPrevLevel;
                    uint256 remappedPower = userPower - amountPrevLevel;
                    uint256 levelProgressBPS = (remappedPower *
                        INVERSE_BASIS_POINT) / remappedAmount;

                    return
                        discountPrevLevelBPS +
                        ((remappedDiscountBPS * levelProgressBPS) /
                            INVERSE_BASIS_POINT);
                }
            }

            // If no match found it means user is >= max possible stake, and therefore has max discount possible
            return stakeLevels[length - 1].discountBPS;
        }
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getStakeLevels()
        external
        pure
        returns (IPremiaStaking.StakeLevel[] memory stakeLevels)
    {
        return _getStakeLevels();
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getStakePeriodMultiplierBPS(
        uint256 period
    ) external pure returns (uint256) {
        return _getStakePeriodMultiplierBPS(period);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getUserInfo(
        address user
    ) external view returns (PremiaStakingStorage.UserInfo memory) {
        return PremiaStakingStorage.layout().userInfo[user];
    }

    function getPendingWithdrawals() external view returns (uint256) {
        return PremiaStakingStorage.layout().pendingWithdrawal;
    }

    function getPendingWithdrawal(
        address user
    )
        external
        view
        returns (uint256 amount, uint256 startDate, uint256 unlockDate)
    {
        PremiaStakingStorage.Layout storage l = PremiaStakingStorage.layout();
        amount = l.withdrawals[user].amount;
        startDate = l.withdrawals[user].startDate;

        unchecked {
            if (startDate > 0) {
                unlockDate = startDate + WITHDRAWAL_DELAY;
            }
        }
    }

    function _decay(
        uint256 pendingRewards,
        uint256 oldTimestamp,
        uint256 newTimestamp
    ) internal pure returns (uint256) {
        return
            ONE_64x64
                .sub(DECAY_RATE_64x64)
                .pow(newTimestamp - oldTimestamp)
                .mulu(pendingRewards);
    }

    function _getStakeLevels()
        internal
        pure
        returns (IPremiaStaking.StakeLevel[] memory stakeLevels)
    {
        stakeLevels = new IPremiaStaking.StakeLevel[](4);

        stakeLevels[0] = IPremiaStaking.StakeLevel(5000 * 1e18, 1000); // -10%
        stakeLevels[1] = IPremiaStaking.StakeLevel(50000 * 1e18, 2500); // -25%
        stakeLevels[2] = IPremiaStaking.StakeLevel(500000 * 1e18, 3500); // -35%
        stakeLevels[3] = IPremiaStaking.StakeLevel(2500000 * 1e18, 6000); // -60%
    }

    function _getStakePeriodMultiplierBPS(
        uint256 period
    ) internal pure returns (uint256) {
        unchecked {
            uint256 oneYear = 365 days;

            if (period == 0) return 2500; // x0.25
            if (period >= 4 * oneYear) return 42500; // x4.25

            return 2500 + (period * 1e4) / oneYear; // 0.25x + 1.0x per year lockup
        }
    }

    function _calculateUserPower(
        uint256 balance,
        uint64 stakePeriod
    ) internal pure returns (uint256) {
        return
            (balance * _getStakePeriodMultiplierBPS(stakePeriod)) /
            INVERSE_BASIS_POINT;
    }

    function _calculateReward(
        uint256 accRewardPerShare,
        uint256 power,
        uint256 rewardDebt
    ) internal pure returns (uint256) {
        return
            ((accRewardPerShare * power) / ACC_REWARD_PRECISION) - rewardDebt;
    }

    function _creditRewards(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        address user,
        uint256 reward,
        uint256 unstakeReward
    ) internal {
        u.reward += reward;

        if (unstakeReward > 0) {
            l.availableUnstakeRewards -= unstakeReward;
            _mint(user, unstakeReward);
            emit EarlyUnstakeRewardCollected(user, unstakeReward);
        }
    }

    function _getInitialUpdateArgsInternal(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        address user
    ) internal view returns (UpdateArgsInternal memory) {
        UpdateArgsInternal memory args;
        args.user = user;
        args.balance = _balanceOf(user);

        if (args.balance > 0) {
            args.oldPower = _calculateUserPower(args.balance, u.stakePeriod);
        }

        args.reward = _calculateReward(
            l.accRewardPerShare,
            args.oldPower,
            u.rewardDebt
        );
        args.unstakeReward = _calculateReward(
            l.accUnstakeRewardPerShare,
            args.oldPower,
            u.unstakeRewardDebt
        );

        return args;
    }

    function _calculateRewardDebt(
        uint256 accRewardPerShare,
        uint256 power
    ) internal pure returns (uint256) {
        return (power * accRewardPerShare) / ACC_REWARD_PRECISION;
    }

    function _updateUser(
        PremiaStakingStorage.Layout storage l,
        PremiaStakingStorage.UserInfo storage u,
        UpdateArgsInternal memory args
    ) internal {
        // Update reward debt
        u.rewardDebt = _calculateRewardDebt(l.accRewardPerShare, args.newPower);
        u.unstakeRewardDebt = _calculateRewardDebt(
            l.accUnstakeRewardPerShare,
            args.newPower
        );

        _creditRewards(l, u, args.user, args.reward, args.unstakeReward);
        _updateTotalPower(l, args.oldPower, args.newPower);
    }

    /**
     * @inheritdoc IPremiaStaking
     */
    function getAvailablePremiaAmount() external view returns (uint256) {
        return _getAvailablePremiaAmount();
    }

    function _getAvailablePremiaAmount() internal view returns (uint256) {
        return
            IERC20(PREMIA).balanceOf(address(this)) -
            PremiaStakingStorage.layout().pendingWithdrawal;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library PremiaStakingStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.staking.PremiaStaking");

    struct Withdrawal {
        uint256 amount; // Premia amount
        uint256 startDate; // Will unlock at startDate + withdrawalDelay
    }

    struct UserInfo {
        uint256 reward; // Amount of rewards accrued which havent been claimed yet
        uint256 rewardDebt; // Debt to subtract from reward calculation
        uint256 unstakeRewardDebt; // Debt to subtract from reward calculation from early unstake fee
        uint64 stakePeriod; // Stake period selected by user
        uint64 lockedUntil; // Timestamp at which the lock ends
    }

    struct Layout {
        uint256 pendingWithdrawal;
        uint256 _deprecated_withdrawalDelay;
        mapping(address => Withdrawal) withdrawals;
        uint256 availableRewards;
        uint256 lastRewardUpdate; // Timestamp of last reward distribution update
        uint256 totalPower; // Total power of all staked tokens (underlying amount with multiplier applied)
        mapping(address => UserInfo) userInfo;
        uint256 accRewardPerShare;
        uint256 accUnstakeRewardPerShare;
        uint256 availableUnstakeRewards;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {PremiaStaking} from "./PremiaStaking.sol";
import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {VxPremiaStorage} from "./VxPremiaStorage.sol";
import {IVxPremia} from "./IVxPremia.sol";

/**
 * @author Premia
 * @title A contract allowing you to use your locked Premia as voting power for mining weights
 */
contract VxPremia is IVxPremia, PremiaStaking {
    constructor(
        address lzEndpoint,
        address premia,
        address rewardToken,
        address exchangeHelper
    ) PremiaStaking(lzEndpoint, premia, rewardToken, exchangeHelper) {}

    function _beforeUnstake(address user, uint256 amount) internal override {
        uint256 votingPowerUnstaked = _calculateUserPower(
            amount,
            PremiaStakingStorage.layout().userInfo[user].stakePeriod
        );

        _subtractExtraUserVotes(
            VxPremiaStorage.layout(),
            user,
            votingPowerUnstaked
        );
    }

    /**
     * @notice subtract user votes, starting from the end of the list, if not enough voting power is left after amountUnstaked is unstaked
     */
    function _subtractExtraUserVotes(
        VxPremiaStorage.Layout storage l,
        address user,
        uint256 amountUnstaked
    ) internal {
        uint256 votingPower = _calculateUserPower(
            _balanceOf(user),
            PremiaStakingStorage.layout().userInfo[user].stakePeriod
        );
        uint256 votingPowerUsed = _calculateUserVotingPowerUsed(user);
        uint256 votingPowerLeftAfterUnstake = votingPower - amountUnstaked;

        unchecked {
            if (votingPowerUsed > votingPowerLeftAfterUnstake) {
                _subtractUserVotes(
                    l,
                    user,
                    votingPowerUsed - votingPowerLeftAfterUnstake
                );
            }
        }
    }

    /**
     * @notice subtract user votes, starting from the end of the list
     */
    function _subtractUserVotes(
        VxPremiaStorage.Layout storage l,
        address user,
        uint256 amount
    ) internal {
        VxPremiaStorage.Vote[] storage userVotes = l.userVotes[user];

        unchecked {
            for (uint256 i = userVotes.length; i > 0; ) {
                VxPremiaStorage.Vote memory vote = userVotes[--i];

                uint256 votesRemoved;

                if (amount < vote.amount) {
                    votesRemoved = amount;
                    userVotes[i].amount -= amount;
                } else {
                    votesRemoved = vote.amount;
                    userVotes.pop();
                }

                amount -= votesRemoved;

                l.votes[vote.version][vote.target] -= votesRemoved;
                emit RemoveVote(user, vote.version, vote.target, votesRemoved);

                if (amount == 0) break;
            }
        }
    }

    function _calculateUserVotingPowerUsed(
        address user
    ) internal view returns (uint256 votingPowerUsed) {
        VxPremiaStorage.Vote[] memory userVotes = VxPremiaStorage
            .layout()
            .userVotes[user];

        unchecked {
            for (uint256 i = 0; i < userVotes.length; i++) {
                votingPowerUsed += userVotes[i].amount;
            }
        }
    }

    /**
     * @inheritdoc IVxPremia
     */
    function getPoolVotes(
        VxPremiaStorage.VoteVersion version,
        bytes memory target
    ) external view returns (uint256) {
        return VxPremiaStorage.layout().votes[version][target];
    }

    /**
     * @inheritdoc IVxPremia
     */
    function getUserVotes(
        address user
    ) external view returns (VxPremiaStorage.Vote[] memory) {
        return VxPremiaStorage.layout().userVotes[user];
    }

    /**
     * @inheritdoc IVxPremia
     */
    function castVotes(VxPremiaStorage.Vote[] memory votes) external {
        VxPremiaStorage.Layout storage l = VxPremiaStorage.layout();

        uint256 userVotingPower = _calculateUserPower(
            _balanceOf(msg.sender),
            PremiaStakingStorage.layout().userInfo[msg.sender].stakePeriod
        );

        VxPremiaStorage.Vote[] storage userVotes = l.userVotes[msg.sender];

        // Remove previous votes
        for (uint256 i = userVotes.length; i > 0; ) {
            VxPremiaStorage.Vote memory vote = userVotes[--i];

            l.votes[vote.version][vote.target] -= vote.amount;
            emit RemoveVote(msg.sender, vote.version, vote.target, vote.amount);

            userVotes.pop();
        }

        // Cast new votes
        uint256 votingPowerUsed = 0;
        for (uint256 i = 0; i < votes.length; i++) {
            VxPremiaStorage.Vote memory vote = votes[i];

            votingPowerUsed += vote.amount;
            if (votingPowerUsed > userVotingPower)
                revert VxPremia__NotEnoughVotingPower();

            userVotes.push(vote);
            l.votes[vote.version][vote.target] += vote.amount;

            emit AddVote(msg.sender, vote.version, vote.target, vote.amount);
        }
    }

    function fixPoolVotes(
        address[] memory users,
        bytes[] memory targets,
        uint256[] memory amounts
    ) external onlyOwner {
        require(
            users.length == targets.length && users.length == amounts.length
        );

        for (uint256 i = 0; i < users.length; i++) {
            VxPremiaStorage.layout().votes[VxPremiaStorage.VoteVersion.V2][
                targets[i]
            ] -= amounts[i];

            // If address passed for user is 0, we dont need to emit the event
            if (users[i] != address(0)) {
                emit RemoveVote(
                    users[i],
                    VxPremiaStorage.VoteVersion.V2,
                    targets[i],
                    amounts[i]
                );
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library VxPremiaStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.staking.VxPremia");

    enum VoteVersion {
        V2 // poolAddress : 20 bytes / isCallPool : 2 bytes
    }

    struct Vote {
        uint256 amount;
        VoteVersion version;
        bytes target;
    }

    struct Layout {
        mapping(address => Vote[]) userVotes;
        // Vote version -> Pool identifier -> Vote amount
        mapping(VoteVersion => mapping(bytes => uint256)) votes;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}