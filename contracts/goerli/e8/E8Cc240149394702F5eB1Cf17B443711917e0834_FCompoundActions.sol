// SPDX-License-Identifier: MIT
/// This is inspired by and based on CompoundBasicProxy.sol by DeFi Saver
/// reference: https://etherscan.io/address/0x336b3919a10ced553c75db18cd285335b8e8ed38#code

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/handlers/compound/IComptroller.sol";
import "contracts/handlers/compound/ICToken.sol";
import "contracts/handlers/compound/ICEther.sol";

contract FCompoundActions {
    // prettier-ignore
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // prettier-ignore
    address public constant CETH_ADDR = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    // prettier-ignore
    address public constant COMPTROLLER_ADDR = 0x05Df6C772A563FfB37fD3E04C1A279Fb30228621;

    /// @notice User deposits tokens to the DSProxy
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _tokenAddr, uint256 _amount) public {
        IERC20(_tokenAddr).transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice User withdraws tokens from the DSProxy
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    function withdraw(address _tokenAddr, uint256 _amount) public {
        if (_tokenAddr == ETH_ADDR) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_tokenAddr).transfer(msg.sender, _amount);
        }
    }

    /// @notice DSProxy borrows tokens from the Compound protocol
    /// @param _cTokenAddr CTokens to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    function borrow(address _cTokenAddr, uint256 _amount) public {
        require(
            ICToken(_cTokenAddr).borrow(_amount) == 0,
            "FCompoundActions: borrow failed"
        );
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Compound protocol
    /// @param _cTokenAddr CTokens to be paybacked
    /// @param _amount Amount of tokens to be payedback
    function repayBorrow(address _cTokenAddr, uint256 _amount) public payable {
        uint256 debt = ICToken(_cTokenAddr).borrowBalanceCurrent(address(this));
        // If given `_amount` is greater than current debt, set `_amount` to current debt otherwise repay will fail
        if (_amount > debt) {
            _amount = debt;
        }

        if (_cTokenAddr == CETH_ADDR) {
            uint256 ethReceived = msg.value;
            ICEther(_cTokenAddr).repayBorrow{value: _amount}();
            // send back the extra eth
            if (ethReceived > _amount) {
                payable(msg.sender).transfer(ethReceived - _amount);
            }
        } else {
            IERC20 token = IERC20(ICToken(_cTokenAddr).underlying());
            token.transferFrom(msg.sender, address(this), _amount);
            if (token.allowance(address(this), _cTokenAddr) < _amount) {
                token.approve(_cTokenAddr, _amount);
            }
            require(
                ICToken(_cTokenAddr).repayBorrow(_amount) == 0,
                "FCompoundActions: repay token failed"
            );
            if (msg.value > 0) payable(msg.sender).transfer(msg.value);
        }
    }

    /// @notice Enters the Compound market so it can be used as collateral
    /// @param _cTokenAddr CToken address of the token
    function enterMarket(address _cTokenAddr) public {
        address[] memory markets = new address[](1);
        markets[0] = _cTokenAddr;
        enterMarkets(markets);
    }

    /// @notice Enters the Compound market so these token can be used as collateral
    /// @param _cTokenAddrs CToken address array to enter market
    function enterMarkets(address[] memory _cTokenAddrs) public {
        uint256[] memory errors =
            IComptroller(COMPTROLLER_ADDR).enterMarkets(_cTokenAddrs);
        for (uint256 i = 0; i < errors.length; i++) {
            require(errors[i] == 0, "FCompoundActions: enter markets failed");
        }
    }

    /// @notice Exits the Compound market so it can't be deposited/borrowed
    /// @param _cTokenAddr CToken address of the token
    function exitMarket(address _cTokenAddr) public {
        require(
            IComptroller(COMPTROLLER_ADDR).exitMarket(_cTokenAddr) == 0,
            "FCompoundActions: exit market failed"
        );
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IComptroller {
    function enterMarkets  (address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);
    function checkMembership(address account, address cToken) external view returns (bool);
    function claimComp(address holder) external;
    function getCompAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICToken {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function underlying() external view returns (address);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function accrualBlockNumber() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICEther {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function admin() external view returns (address);
    function pendingAdmin() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function accrualBlockNumber() external view returns (uint256);
    function borrowIndex() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}