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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DepositTokens {
    IERC20 public tokenAddress;
    uint256[] slabCapacity = [100, 200, 300, 400, 500];
    uint256 _slabCount = 4;

    struct DepositInfo {
        uint256 slabCount;
        uint256 amount;
      
    }

    mapping(address => DepositInfo[])  AmountInSlab;

    constructor(address _tokenAddress) {
        tokenAddress = IERC20(_tokenAddress);
    }

    function displaySlabCapacity() external view returns(uint[] memory){
       return slabCapacity;
    }

    function ApproveDepositor(address user, uint amt) external {
        tokenAddress.approve(user, amt);
    }

    function Deposit(uint256 _amount) external {
        require(_amount > 0, "insufficient balance");
        tokenAddress.transferFrom(msg.sender, address(this), _amount);
        uint256 remaining_amt;
        if (slabCapacity[_slabCount] > 0 && _slabCount >= 0) {
            if (_amount > slabCapacity[_slabCount]) {
                remaining_amt = _amount - slabCapacity[_slabCount];
                slabCapacity[_slabCount] -= slabCapacity[_slabCount];
                AmountInSlab[msg.sender].push(DepositInfo(_slabCount, _amount-remaining_amt));
                _slabCount--;
                slabCapacity[_slabCount] -= remaining_amt;
                AmountInSlab[msg.sender].push(DepositInfo(_slabCount, remaining_amt));
            } else {
                slabCapacity[_slabCount] -= _amount;
                AmountInSlab[msg.sender].push(DepositInfo(_slabCount,_amount));
            }
        } else if (slabCapacity[_slabCount] == 0 && _slabCount >= 0) {
            _slabCount--;
             if (_amount > slabCapacity[_slabCount]) {
                remaining_amt = _amount - slabCapacity[_slabCount];
                slabCapacity[_slabCount] -= slabCapacity[_slabCount];
                AmountInSlab[msg.sender].push(DepositInfo(_slabCount, _amount-remaining_amt));
                _slabCount--;
                slabCapacity[_slabCount] -= remaining_amt;
                AmountInSlab[msg.sender].push(DepositInfo( _slabCount,remaining_amt));
            } else {
                slabCapacity[_slabCount] -= _amount;
                AmountInSlab[msg.sender].push(DepositInfo(_slabCount, _amount));
            }
        }
       
    }

    function enquire() external view returns (DepositInfo[] memory) {
        return AmountInSlab[msg.sender];
    }

    //wihdraw by slab index

    function withdrawTokens(uint slab) external {

        uint withdraw_amt;
        DepositInfo[] storage depositinfo = AmountInSlab[msg.sender];
     
        for(uint i=0; i< depositinfo.length; i++){
            if(depositinfo[i].slabCount == slab){
                withdraw_amt += depositinfo[i].amount;
                slabCapacity[depositinfo[i].slabCount] += depositinfo[i].amount;
                delete depositinfo[i];
            }
        }
        tokenAddress.transfer( msg.sender, withdraw_amt);

    }
}