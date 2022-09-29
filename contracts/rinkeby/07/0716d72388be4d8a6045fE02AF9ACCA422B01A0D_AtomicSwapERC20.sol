/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol



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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/Approval Contract.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


contract AtomicSwapERC20 {

    struct Swap {
        uint256 startTime;
        uint256 timelock;
        uint256 erc20ValueT;
        address erc20ContractAddressT;
        uint256 erc20ValueWDT;
        address erc20ContractAddressWDT;
        address erc20Trader;
        address withdrawTrader;
    }

    enum States {
        OPEN,
        CLOSED,
        EXPIRED
    }

    mapping (uint256 => Swap) public swaps;
    mapping (uint256 => States) public swapStates;

    event Open(uint256 _swapID, uint256 _erc20ValueT, address _erc20ContractAddressT, address _withdrawTrader, uint256 _erc20ValueWDT, address _erc20ContractAddressWDT, uint256 _timelock);
    event Expire(uint256 _swapID);
    event Close(uint256 _swapID);

    function open(uint256 _swapID, uint256 _erc20ValueT, address _erc20ContractAddressT, uint256 _erc20ValueWDT, address _erc20ContractAddressWDT, address _withdrawTrader,
    uint256 _timelock) public {

        // Transfer value from the ERC20 trader to this contract.
        IERC20 erc20ContractT = IERC20(_erc20ContractAddressT);
        require(erc20ContractT.allowance(msg.sender, address(this)) >= _erc20ValueT);
        require(erc20ContractT.transferFrom(msg.sender, address(this), _erc20ValueT));


        // Store the details of the swap.
        Swap memory swap = Swap({
            startTime: block.timestamp,
            timelock: _timelock,
            erc20ValueT: _erc20ValueT,
            erc20ContractAddressT: _erc20ContractAddressT,
            erc20ValueWDT: _erc20ValueWDT,
            erc20ContractAddressWDT: _erc20ContractAddressWDT,
            erc20Trader: msg.sender,
            withdrawTrader: _withdrawTrader
        });

        swaps[_swapID] = swap;
        swapStates[_swapID] = States.OPEN;

        emit Open(
            _swapID,
            _erc20ValueT,
            _erc20ContractAddressT,
            _withdrawTrader,
            _erc20ValueWDT,
            _erc20ContractAddressWDT,
            _timelock
            );
    }


    function expire(uint256 _swapID) public onlyOpenSwaps(_swapID) onlyErc20Trader(_swapID) onlyExpirableSwaps(_swapID) {
    
        // Expire the swap.
        Swap memory swap = swaps[_swapID];
        swapStates[_swapID] = States.EXPIRED;

        // Transfer the ERC20 value from this contract back to the ERC20 trader.
        IERC20 erc20ContractT = IERC20(swap.erc20ContractAddressT);
        require(erc20ContractT.transfer(swap.erc20Trader, swap.erc20ValueT));

        emit Expire(_swapID);
    }



    function check(uint256 _swapID) public view returns (
        uint256 timelock,

        address erc20ContractAddressT, 
        uint256 erc20ValueT,

        address erc20ContractAddressWDT, 
        uint256 erc20ValueWDT,

        address withdrawTrader,
        address erc20Trader)

    {
        Swap memory swap = swaps[_swapID];
        return (
            swap.timelock,

            swap.erc20ContractAddressT,
            swap.erc20ValueT,

            swap.erc20ContractAddressWDT,
            swap.erc20ValueWDT,

            swap.withdrawTrader,
            swap.erc20Trader );
    }


 function close(uint256 _swapID) public onlyOpenSwaps(_swapID) onlyWithdrawTrader(_swapID) {

        // Close the swap.
        Swap memory swap = swaps[_swapID];
        swapStates[_swapID] = States.CLOSED;

        IERC20 erc20ContractT = IERC20(swap.erc20ContractAddressT);
        IERC20 erc20ContractWDT = IERC20(swap.erc20ContractAddressWDT);

        require(swap.erc20ValueWDT <= erc20ContractWDT.allowance(msg.sender, address(this)));

        //Transfer the ERC20 funds from the Withdraw trader to this contract
        require(erc20ContractWDT.transferFrom(msg.sender, address(this), swap.erc20ValueWDT));

        // Transfer the ERC20 funds from this contract to the withdrawing trader.
        require(erc20ContractT.transfer(swap.withdrawTrader, swap.erc20ValueT));

        // Transfer the ERC20 funds from this contract to the opening trader.
        require(erc20ContractWDT.transfer(swap.erc20Trader, swap.erc20ValueWDT));

        emit Close(_swapID);
    }


    modifier onlyErc20Trader(uint256 _swapID) {
        require(msg.sender == swaps[_swapID].erc20Trader, "Only the trader who initiated can expire the trade!");
        _;
    }

    modifier onlyOpenSwaps(uint256 _swapID) {
        require(swapStates[_swapID] == States.OPEN);
        _;
    }

    modifier onlyWithdrawTrader(uint256 _swapID) {
        require(msg.sender == swaps[_swapID].withdrawTrader, "Only the Withdraw Trader Can close the trade!");
        _;
    }

    modifier onlyExpirableSwaps(uint256 _swapID) {
        require(block.timestamp > swaps[_swapID].startTime + swaps[_swapID].timelock, "You cant expire the trade before timeLock!");
        _;
    }

}