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
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balanceOf(account);
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address holder,
        address spender
    ) public view virtual returns (uint256) {
        return _allowance(holder, spender);
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
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

    function setName(Layout storage l, string memory name) internal {
        l.name = name;
    }

    function setSymbol(Layout storage l, string memory symbol) internal {
        l.symbol = symbol;
    }

    function setDecimals(Layout storage l, uint8 decimals) internal {
        l.decimals = decimals;
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
pragma solidity ^0.8.0;

import {ERC20Base} from "@solidstate/contracts/token/ERC20/base/ERC20Base.sol";
import {ERC20Extended} from "@solidstate/contracts/token/ERC20/extended/ERC20Extended.sol";
import {ERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/ERC20Metadata.sol";

contract HRVSTFacet is ERC20Base, ERC20Extended, ERC20Metadata {
  function mint() external {
    uint256 amount = 1e18;
    _mint(msg.sender, amount);
  }

  function mintTo(address _user) external {
    uint256 amount = 1e18;
    _mint(_user, amount);
  }
}