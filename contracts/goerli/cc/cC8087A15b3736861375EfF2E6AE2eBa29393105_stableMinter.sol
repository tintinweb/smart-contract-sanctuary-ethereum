// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import { IERC20Mintable } from "./IERC20Mintable.sol";

enum Coin {
    USDT,
    USDC,
    EURS
}

contract stableMinter {
    address public constant USDT = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49;
    address public constant USDC = 0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43;
    address public constant EURS = 0xc31E63CB07209DFD2c7Edb3FB385331be2a17209;

    function mintStables(Coin coin, uint256 amount) public {
        if (coin == Coin.USDT) {
            USDT.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
        }
        if (coin == Coin.USDC) {
            USDC.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
        }
        if (coin == Coin.EURS) {
            EURS.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
        }
    }

    function mintUSDT() external {
        mintStables(Coin.USDT, 10000);
    }

    function mintUSDC() external {
        mintStables(Coin.USDC, 10000);
    }

    function mintEURS() external {
        mintStables(Coin.EURS, 10000);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

import { IERC20Base } from "@solidstate/contracts/token/ERC20/base/IERC20Base.sol";

interface IERC20Mintable is IERC20Base {
  function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {

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
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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