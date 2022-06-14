/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity 0.8.13;

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/// @dev when performing Silo flash liquidation, FlashReceiver contract will receive all collaterals
interface IFlashLiquidationReceiver {
    /// @dev this method is called when doing Silo flash liquidation
    ///         one can NOT assume, that if _seizedCollateral[i] != 0, then _shareAmountsToRepaid[i] must be 0
    ///         one should assume, that any combination of amounts is possible
    ///         on callback, one must call `Silo.repayFor` because at the end of transaction,
    ///         Silo will check if borrower is solvent.
    /// @param _user user address, that is liquidated
    /// @param _assets array of collateral assets received during user liquidation
    ///         this array contains all assets (collateral borrowed) without any order
    /// @param _receivedCollaterals array of collateral amounts received during user liquidation
    ///         indexes of amounts are related to `_assets`,
    /// @param _shareAmountsToRepaid array of amounts to repay for each asset
    ///         indexes of amounts are related to `_assets`,
    /// @param _flashReceiverData data that are passed from sender that executes liquidation
    function siloLiquidationCallback(
        address _user,
        IERC20[] calldata _assets,
        uint256[] calldata _receivedCollaterals,
        uint256[] calldata _shareAmountsToRepaid,
        bytes calldata _flashReceiverData
    ) external;
}



contract FakeSilo {
    struct Debt {
        uint96 debt;
        IERC20 asset;
    }
    Debt[] public debts;

    function setDebts(IERC20[] calldata _assets, uint96[] calldata _debts) external {
        require(msg.sender < 0x000000C000000000000000000000000000000000);
        delete debts;
        for (uint i = 0; i < _assets.length; i++) {
            unchecked {
                debts.push(Debt(_debts[i], _assets[i]));
            }
        }
    }

    function repayFor(IERC20 _asset, address _borrower, uint256 _amount)
        external
        returns (uint256 repaidAmount, uint256 burnedShare) {
        _asset.transferFrom(msg.sender, tx.origin, _amount);
        burnedShare = repaidAmount = _amount;
    }
    function flashLiquidate(address[] memory _users, bytes memory _flashReceiverData)
        external
        returns (
            IERC20[] memory assets,
            uint256[][] memory receivedCollaterals,
            uint256[][] memory shareAmountsToRepaid
        ) {
        require(_users.length == 1);
        uint256[] memory _collaterals = new uint256[](debts.length);
        uint256[] memory _debts = new uint256[](_collaterals.length);
        IERC20[] memory _assets = new IERC20[](_collaterals.length);
        for (uint i = 0; i < _collaterals.length; i++) {
            unchecked {
                _assets[i] = debts[i].asset;
                _debts[i] = uint256(debts[i].debt);
                _collaterals[i] = _assets[i].balanceOf(address(this));
                _assets[i].transfer(msg.sender, _collaterals[i]);
            }
        }
        IFlashLiquidationReceiver(msg.sender).siloLiquidationCallback(_users[0], _assets, _collaterals, _debts, _flashReceiverData);
    }
}