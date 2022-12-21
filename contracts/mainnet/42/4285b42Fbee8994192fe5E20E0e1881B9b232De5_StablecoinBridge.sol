/**
* SPDX-License-Identifier: MIT
*
* Copyright (c) 2016-2019 zOS Global Limited
*
*/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */

interface IERC20 {

    // Optional functions
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferAndCall(address recipient, uint256 amount, bytes calldata data) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC677Receiver {
    
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReserve.sol";

interface IFrankencoin is IERC20 {

    function suggestMinter(address _minter, uint256 _applicationPeriod, 
      uint256 _applicationFee, string calldata _message) external;

    function registerPosition(address position) external;

    function denyMinter(address minter, address[] calldata helpers, string calldata message) external;

    function reserve() external view returns (IReserve);

    function isMinter(address minter) external view returns (bool);

    function isPosition(address position) external view returns (address);
    
    function mint(address target, uint256 amount) external;

    function mint(address target, uint256 amount, uint32 reservePPM, uint32 feePPM) external;

    function burn(uint256 amountIncludingReserve, uint32 reservePPM) external;

    function burnFrom(address payer, uint256 targetTotalBurnAmount, uint32 _reservePPM) external returns (uint256);

    function burnWithReserve(uint256 amountExcludingReserve, uint32 reservePPM) external returns (uint256);

    function burn(address target, uint256 amount) external;

    function notifyLoss(uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReserve {
   function isQualified(address sender, address[] calldata helpers) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC677Receiver.sol";
import "./IFrankencoin.sol";

/**
 * A minting contract for another CHF stablecoin that we trust.
 */
contract StablecoinBridge {

    IERC20 public immutable chf;
    IFrankencoin public immutable zchf;

    uint256 public immutable horizon;
    uint256 public immutable limit;

    constructor(address other, address zchfAddress, uint256 limit_){
        chf = IERC20(other);
        zchf = IFrankencoin(zchfAddress);
        horizon = block.timestamp + 52 weeks;
        limit = limit_;
    }

    function mint(uint256 amount) external {
        mint(msg.sender, amount);
    }

    function mint(address target, uint256 amount) public {
        chf.transferFrom(msg.sender, address(this), amount);
        mintInternal(target, amount);
    }

    function mintInternal(address target, uint256 amount) internal {
        require(block.timestamp <= horizon, "expired");
        require(chf.balanceOf(address(this)) <= limit, "limit");
        zchf.mint(target, amount);
    }
    
    function burn(uint256 amount) external {
        burnInternal(msg.sender, msg.sender, amount);
    }

    function burn(address target, uint256 amount) external {
        burnInternal(msg.sender, target, amount);
    }

    function burnInternal(address zchfHolder, address target, uint256 amount) internal {
        zchf.burn(zchfHolder, amount);
        chf.transfer(target, amount);
    }

    function onTokenTransfer(address from, uint256 amount, bytes calldata) external returns (bool){
        if (msg.sender == address(chf)){
            mintInternal(from, amount);
        } else if (msg.sender == address(zchf)){
            burnInternal(address(this), from, amount);
        } else {
            require(false, "unsupported token");
        }
        return true;
    }
    
}