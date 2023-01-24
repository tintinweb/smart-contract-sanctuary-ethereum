/**
 *Submitted for verification at Etherscan.io on 2023-01-24
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

// File: contracts/swap.sol

//Swap Contract
// --> Swap contract is a contract where two persons can swap their tokens with each other.
//--> Standard for those tokens will be ERC20 standard.
// --> Person A -- WIll initiate the transaction by opening a swap.
// --> function openSwap (swapId, erc20ContractAddressDT, erc20TokenAmountDT, erc20ContractAddressWDT, erc20TokenAmountWDt, lockTime)
// --> Modifier (Balance Check, swapId)
// --> function close (swapId)
// --> Modifier (BalanceCheck, onlyOpenSwap, notThePersonWhoInitiatedSwap
// --> function expire (swapId)
// --> Modifier (onlyOpenSwap, personWhoInitiatedSwap, onlyExpirableSwaps)
// --> function check (swapId) 102 --> 
// --> function modifySwap(swapId) -- Homework
// --> Modifier onlyOpenSwap, personWhoInitiatedSwap
// --> Person B -- Will complete the swap.

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


contract AtomicSwapERC20 {

    struct Swap{
       uint256 swapId;
       uint256 startTime;
       uint256 timeLock;
       address erc20ContractAddressDT;
       address erc20ContractAddressWDT;
       uint256 erc20TokenAmountDT;
       uint256 erc20TokenAmountWDT;
       address whoInitiatedTrade;
    }

    enum States {
        OPEN,
        CLOSED,
        EXPIRE
    } 

    mapping (uint256 => Swap) public swaps;
    mapping (uint256 => States) public swapStates;

    event Open(uint256 _swapID, uint256 _timelock, address _erc20ContractAddressDT, address _erc20ContractAddressWDT,   uint256 _erc20TokenAmountDT,  uint256 _erc20TokenAmountWDT, address _whoInitiatedTrade );
    event Close(uint256 swapId);

    function open(uint256 _swapId, address _erc20ContractAddressDT, uint256 _erc20ValueDT,
        address _erc20ContractAddressWDT, uint256 _erc20ValueWDT, uint256 _timeLock) public {
            IERC20 erc20ContractDT = IERC20(_erc20ContractAddressDT);
            require(erc20ContractDT.allowance(msg.sender, address(this)) >= _erc20ValueDT); //1st
            require(erc20ContractDT.transferFrom(msg.sender, address(this), _erc20ValueDT)); //2nd

        Swap memory swap = Swap({
            swapId: _swapId,
            startTime: block.timestamp,
            timeLock: _timeLock,
            erc20ContractAddressDT: _erc20ContractAddressDT,
            erc20ContractAddressWDT: _erc20ContractAddressWDT,
            erc20TokenAmountDT: _erc20ValueDT,
            erc20TokenAmountWDT: _erc20ValueWDT,
            whoInitiatedTrade: msg.sender
        });

        swaps[_swapId] = swap;
        swapStates[_swapId] = States.OPEN;

        emit Open(
            _swapId,
            _timeLock,
            _erc20ContractAddressDT,
            _erc20ContractAddressWDT,
            _erc20ValueDT,
            _erc20ValueWDT,
            msg.sender
        );
        }

    function close(uint256 _swapId) public onlyOpenSwaps(_swapId) notThePersonWhoInitiatedSwap(_swapId) {
        Swap memory swap = swaps[_swapId];
        swapStates[_swapId] = States.CLOSED;


        IERC20 erc20ContractAddressDT = IERC20(swap.erc20ContractAddressDT);
        IERC20 erc20ContractAddressWDT = IERC20(swap.erc20ContractAddressWDT);

        require(swap.erc20TokenAmountWDT <= erc20ContractAddressWDT.allowance(msg.sender, address(this)));

        //Transfer the erc20 funds from the withdraw trader to this contract
        require(erc20ContractAddressWDT.transferFrom(msg.sender, address(this), swap.erc20TokenAmountWDT));

        //Transfer the erc20 funds from this contract to the closing trader
        require(erc20ContractAddressDT.transfer(msg.sender, swap.erc20TokenAmountDT));

        //Transfer the erc20 funds from this contract to the trader who initiated the trade
        require(erc20ContractAddressWDT.transfer(swap.whoInitiatedTrade, swap.erc20TokenAmountWDT));

        emit Close(_swapId);
    }


    function expire(uint256 _swapId) public onlyOpenSwaps(_swapId) onlyOwnerofSwap(_swapId) {
        
        swapStates[_swapId] = States.EXPIRE;
        //Swap memory swap = swaps[_swapId];
        IERC20 erc20Contract = IERC20(swaps[_swapId].erc20ContractAddressDT);
        require(erc20Contract.transfer(swaps[_swapId].whoInitiatedTrade, swaps[_swapId].erc20TokenAmountDT));

       // emit Expire(_swapId);

    }


    function check(uint256 _swapId) public view returns (
        address erc20ContractAddressDT,
        uint256 erc20TokenAmountDT,

        address erc20ContractAddressWDT,
        uint256 erc20TokenAmountWDT,

        uint256 timeLock,
        address whoInitiatedTrade
    ) {
        Swap memory swap = swaps[_swapId];
        return(
            swap.erc20ContractAddressDT,
            swap.erc20TokenAmountDT,
            swap.erc20ContractAddressWDT,
            swap.erc20TokenAmountWDT,
            swap.timeLock,
            swap.whoInitiatedTrade
        );
    }
     function modifySwap(uint256 _swapId, address _erc20ContractAddressDT, uint256 _erc20ValueDT,
        address _erc20ContractAddressWDT, uint256 _erc20ValueWDT, uint256 _timeLock) public onlyOwnerofSwap(_swapId) {
            IERC20 erc20ContractDT = IERC20(_erc20ContractAddressDT);
            require(erc20ContractDT.allowance(msg.sender, address(this)) >= _erc20ValueDT); //1st
            require(erc20ContractDT.transferFrom(msg.sender, address(this), _erc20ValueDT)); //2nd

        Swap memory swap = Swap({
            swapId: _swapId,
            startTime: block.timestamp,
            timeLock: _timeLock,
            erc20ContractAddressDT: _erc20ContractAddressDT,
            erc20ContractAddressWDT: _erc20ContractAddressWDT,
            erc20TokenAmountDT: _erc20ValueDT,
            erc20TokenAmountWDT: _erc20ValueWDT,
            whoInitiatedTrade: msg.sender
        });

        swaps[_swapId] = swap;
        swapStates[_swapId] = States.OPEN;

        emit Open(
            _swapId,
            _timeLock,
            _erc20ContractAddressDT,
            _erc20ContractAddressWDT,
            _erc20ValueDT,
            _erc20ValueWDT,
            msg.sender
        );
        }




    modifier onlyOpenSwaps(uint256 _swapId) {
        require(swapStates[_swapId] == States.OPEN, "Its not OPEN for swap!");
        _;
    }

    modifier onlyOwnerofSwap(uint256 _swapId) {
        require(msg.sender == swaps[_swapId].whoInitiatedTrade, "You are not person who initiated the trade!");
        _;
    }
    modifier notThePersonWhoInitiatedSwap(uint256 _swapId) {
        require(msg.sender != swaps[_swapId].whoInitiatedTrade, "Owner cannot close the trade");
        _;
    }

}