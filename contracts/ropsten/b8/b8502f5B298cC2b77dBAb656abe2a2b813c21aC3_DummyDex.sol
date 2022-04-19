/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.10;



// Part: Address

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Part: SafeMath

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSubR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b <= a, s);
        c = a - b;
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
    function safeDivR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b > 0, s);
        c = a / b;
    }
}

// Part: TokenInterface

contract TokenInterface{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

// Part: SafeERC20

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: DummyDex.sol

contract DummyDex{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address[2] public token;
  constructor(address _t0, address _t1, uint256 _m0, uint256 _m1) public{
    token[0] = _t0;
    token[1] = _t1;
    TokenInterface(_t0).generateTokens(address(this), _m0);
    TokenInterface(_t1).generateTokens(address(this), _m1);
  }

  event Swap(uint256 In, uint256 Out, uint256 reserve0, uint256 reserve1);

  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to) public returns (uint256 amounts) {
    address t0 = path[0];
    address t1 = path[path.length - 1];
    require(IERC20(t0).balanceOf(address(this)) > 0, "no liquidity");
    require(IERC20(t1).balanceOf(address(this)) > 0, "no liquidity");
    //emit SwapBefore(IERC20(token[0]).balanceOf(address(this)), IERC20(token[1]).balanceOf(address(this)));

    IERC20(t0).safeTransferFrom(msg.sender, address(this), amountIn);
    uint256 amountOut = amountIn*(IERC20(t1).balanceOf(address(this)))/(IERC20(t0).balanceOf(address(this)));
    IERC20(t1).safeTransfer(msg.sender, amountOut);
    emit Swap(amountIn, amountOut, IERC20(token[0]).balanceOf(address(this)), IERC20(token[1]).balanceOf(address(this)));
    return amountOut;
  }

  function exchange(uint256 i, uint256 j, uint256 amountIn, uint256 min_amount) public returns(uint256){
    uint256 j0 = j;
    if (j0 == 2) {j0 = 1;}
    address t0 = token[i];
    address t1 = token[j];
    IERC20(t0).safeTransferFrom(msg.sender, address(this), amountIn);
    uint256 amountOut = amountIn * (IERC20(t1).balanceOf(address(this)))/(IERC20(t0).balanceOf(address(this)));
    IERC20(t1).safeTransfer(msg.sender, amountOut);
    emit Swap(amountIn, amountOut, IERC20(token[0]).balanceOf(address(this)), IERC20(token[1]).balanceOf(address(this)));
    return amountOut;
  }

}