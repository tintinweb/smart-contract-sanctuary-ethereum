/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// File: transfer.sol


pragma solidity ^0.8.0;


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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract SendEther {
    constructor() payable {
        owner = msg.sender;
    }

    address owner;

    function transferEth(
        address payable _to, 
        uint256 _value
    ) external payable {
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;
        afterValue = afterValue + _value;
        _to.transfer(_value);
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            payable(msg.sender).transfer(remainingValue);
        }
    }

    function transferEthToMulti(
        address payable[] calldata _to
    ) external payable {
        // 将剩余所有的币转给最后一个钱包
        uint256 perValue = msg.value / _to.length;
        uint256 remainValue = msg.value;
        for (uint8 i = 0; i < _to.length; i++) {
            remainValue = remainValue - perValue;
            if ( i + 1 == _to.length) {
                _to[i].transfer(remainValue);
            } else {
                _to[i].transfer(perValue);
            }
            
        }
    }

    function transferEthToMulti_2(
        address payable[] calldata _to, 
        uint256[] calldata _value
    ) external payable {
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;
        for (uint8 i = 0; i < _to.length; i++) {
            afterValue = afterValue + _value[i];
            _to[i].transfer(_value[i]);
        }
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            payable(msg.sender).transfer(remainingValue);
        }
    }

    function transferToken(
        address _tokenAddress,
        address _to,
        uint256 _value
    ) external returns (bool _success) {
        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, _to, _value);
        return true;
    }

    function transferTokenToMulti(
        address _tokenAddress,
        address[] calldata _to,
        uint256 _value
    ) external returns (bool _success) {
        assert(_to.length <= 255);
        IERC20 token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value);
        }
        return true;
    }

    function transferTokenToMulti_2(
        address _tokenAddress,
        address[] calldata _to,
        uint256[] calldata _value
    ) external returns (bool _success) {
        assert(_to.length <= 255);
        IERC20 token = IERC20(_tokenAddress);
        for (uint256 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
        }
        return true;
    }

}