//SPDX-License-Identifier: 3BSD
pragma solidity ^0.8.0;

import "./events.sol";

import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";

    /*///////////////////////////////////////////////////////////////
                        RAINSHOWER ERC20 BORROW
          Created by a factory contract to represent positions
    //////////////////////////////////////////////////////////////*/


contract RainshowerContract is Events {

    /*///////////////////////////////////////////////////////////////
                            CONTRACY STORAGE                        
    //////////////////////////////////////////////////////////////*/
    uint256 public immutable tokensForBorrow; // Ammount of tokens that can be borrowed
    address public immutable tokensForBorrowAddress; // Address of the token

    address public immutable baseTokenAddress; // Address of the token that will be used for margin, must have a pair with tokensForBorrow 
    uint256 public immutable maintanenceMargin; // Collateralization ratio

    /*///////////////////////////////////////////////////////////////
                        UniV3 TWAP BASED ORACLE
            can be changed by the borrow creator to a more
                         suited one if needed
    //////////////////////////////////////////////////////////////*/
    address public immutable oracleAddress;

    address public immutable borrowMaker; // Address of who created an open borrow
    address public borrowTaker; // Address who borrowed the tokens
    address public counterpartyAddress; // Can be set to only allow a specific address to take the borrow

    /*
        A contract can have 4 states:
        0 - Not funded with tokens
        1 - Funded and open for anyone to take
        2 - Funded with collateral, swapped the token, in progress
        3 - Closed
    */
    uint8 public state = 0;

    /*///////////////////////////////////////////////////////////////
                            MODULE STORAGE
         Modules are a way to simplify and extend rainshower to
         be used for any purpouse where token borrows are wanted.
    //////////////////////////////////////////////////////////////*/
    address public immutable moduleAddress;
    bytes public data;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor (uint256 _tokensForBorrow, address _tokensForBorrowAddress, address _baseTokenAddress,
                 uint256 _maintanenceMargin, address _oracleAddress, address _moduleAddressd, bytes memory _data) {
        tokensForBorrow = _tokensForBorrow;
        tokensForBorrowAddress = _tokensForBorrowAddress;
        baseTokenAddress = _baseTokenAddress;
        maintanenceMargin = _maintanenceMargin;
        oracleAddress = _oracleAddress;
        moduleAddress = _moduleAddressd;
        data = _data;
        borrowMaker = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                        RAINSHOWER POSITION LOGIC
    //////////////////////////////////////////////////////////////*/

    function fundWithTokensAndOpen () external returns(bool) {
        (bool _condition, ) =
        moduleAddress.delegatecall(abi.encodeWithSignature("onFundWithTokensAndOpen(address)", address(this)));

        emit fundWithTokensAndOpenEvent(address(this), msg.sender);
        return _condition;
    }

    function fundWithMarginAndOpen (uint256 _extraMargin) external returns(bool) {
        (bool _condition, ) =
        moduleAddress.delegatecall(abi.encodeWithSignature("onFundWithTokensAndOpen(address, uint256)", address(this), _extraMargin));
        
        emit fundWithMarginAndOpenEvent(address(this), msg.sender);
        return _condition;
    }

    function close () external returns(bool) {
        (bool _condition, ) =
        moduleAddress.delegatecall(abi.encodeWithSignature("onClose(address)", address(this)));

        emit closeEvent(address(this), msg.sender);

        return _condition;
    }

    function liquidate () external returns(bool) {
        (bool _condition, ) =
        moduleAddress.delegatecall(abi.encodeWithSignature("onLiquidation(address)", address(this)));

        emit closeEvent(address(this), msg.sender);

        return _condition;
    }
}

//SPDX-License-Identifier: 3BSD
pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * The Events contract contains events for rainshower borrows
 */
abstract contract Events {
	event fundWithTokensAndOpenEvent(address borrow, address sender);
	event fundWithMarginAndOpenEvent(address borrow, address sender);
	event closeEvent(address borrow, address sender);
	event liquidation(address liquidator, address borrowAddress);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}