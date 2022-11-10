/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

/**
 *Submitted for verification at BscScan.com on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending NATIVE that do not consistently return true/false
library TransferHelper {
    function safeTransferNative(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: NATIVE_TRANSFER_FAILED');
    }
}

interface IwNATIVE {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface AnyswapV1ERC20 {
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);
    function setMinter(address _auth) external;
    function applyMinter() external;
    function revokeMinter(address _auth) external;
    function changeVault(address newVault) external returns (bool);
    function depositVault(uint amount, address to) external returns (uint);
    function withdrawVault(address from, uint amount, address to) external returns (uint);
    function underlying() external view returns (address);
    function deposit(uint amount, address to) external returns (uint);
    function withdraw(uint amount, address to) external returns (uint);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
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

contract AnyswapV6Router {
    using SafeERC20 for IERC20;

    address public constant factory = address(0);
    address public immutable wNATIVE;

    // delay for timelock functions
    uint public constant DELAY = 2 days;

    constructor(address _wNATIVE, address _mpc) {
        _newMPC = _mpc;
        _newMPCEffectiveTime = block.timestamp;
        wNATIVE = _wNATIVE;
    }

    receive() external payable {
        assert(msg.sender == wNATIVE); // only accept Native via fallback from the wNative contract
    }

    address private _oldMPC;
    address private _newMPC;
    uint256 private _newMPCEffectiveTime;

    event LogChangeMPC(address indexed oldMPC, address indexed newMPC, uint indexed effectiveTime, uint chainID);
    event LogAnySwapIn(bytes32 indexed txhash, address indexed token, address indexed to, uint amount, uint fromChainID, uint toChainID);
    event LogAnySwapOut(address indexed token, address indexed from, address indexed to, uint amount, uint fromChainID, uint toChainID);
    event LogAnySwapOut(address indexed token, address indexed from, string to, uint amount, uint fromChainID, uint toChainID);

    modifier onlyMPC() {
        require(msg.sender == mpc(), "AnyswapV6Router: FORBIDDEN");
        _;
    }

    function mpc() public view returns (address) {
        if (block.timestamp >= _newMPCEffectiveTime) {
            return _newMPC;
        }
        return _oldMPC;
    }

    function cID() public view returns (uint) {
        return block.chainid;
    }

    function changeMPC(address newMPC) external onlyMPC returns (bool) {
        require(newMPC != address(0), "AnyswapV6Router: address(0)");
        _oldMPC = mpc();
        _newMPC = newMPC;
        _newMPCEffectiveTime = block.timestamp + DELAY;
        emit LogChangeMPC(_oldMPC, _newMPC, _newMPCEffectiveTime, cID());
        return true;
    }

    function changeVault(address token, address newVault) external onlyMPC returns (bool) {
        return AnyswapV1ERC20(token).changeVault(newVault);
    }

    function setMinter(address token, address _auth) external onlyMPC {
        return AnyswapV1ERC20(token).setMinter(_auth);
    }

    function applyMinter(address token) external onlyMPC {
        return AnyswapV1ERC20(token).applyMinter();
    }

    function revokeMinter(address token, address _auth) external onlyMPC {
        return AnyswapV1ERC20(token).revokeMinter(_auth);
    }

    function _anySwapOut(address from, address token, address to, uint amount, uint toChainID) internal {
        AnyswapV1ERC20(token).burn(from, amount);
        emit LogAnySwapOut(token, from, to, amount, cID(), toChainID);
    }

    // Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to`
    function anySwapOut(address token, address to, uint amount, uint toChainID) external {
        _anySwapOut(msg.sender, token, to, amount, toChainID);
    }

    // Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to` by minting with `underlying`
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external {
        address _underlying = AnyswapV1ERC20(token).underlying();
        require(_underlying != address(0), "AnyswapV6Router: no underlying");
        IERC20(_underlying).safeTransferFrom(msg.sender, token, amount);
        emit LogAnySwapOut(token, msg.sender, to, amount, cID(), toChainID);
    }

    function anySwapOutNative(address token, address to, uint toChainID) external payable {
        require(wNATIVE != address(0), "AnyswapV6Router: zero wNATIVE");
        require(AnyswapV1ERC20(token).underlying() == wNATIVE, "AnyswapV6Router: underlying is not wNATIVE");
        IwNATIVE(wNATIVE).deposit{value: msg.value}();
        assert(IwNATIVE(wNATIVE).transfer(token, msg.value));
        emit LogAnySwapOut(token, msg.sender, to, msg.value, cID(), toChainID);
    }

    function anySwapOut(address[] calldata tokens, address[] calldata to, uint[] calldata amounts, uint[] calldata toChainIDs) external {
        for (uint i = 0; i < tokens.length; i++) {
            _anySwapOut(msg.sender, tokens[i], to[i], amounts[i], toChainIDs[i]);
        }
    }

    function anySwapOut(address token, string memory to, uint amount, uint toChainID) external {
        AnyswapV1ERC20(token).burn(msg.sender, amount);
        emit LogAnySwapOut(token, msg.sender, to, amount, cID(), toChainID);
    }

    function anySwapOutUnderlying(address token, string memory to, uint amount, uint toChainID) external {
        address _underlying = AnyswapV1ERC20(token).underlying();
        require(_underlying != address(0), "AnyswapV6Router: no underlying");
        IERC20(_underlying).safeTransferFrom(msg.sender, token, amount);
        emit LogAnySwapOut(token, msg.sender, to, amount, cID(), toChainID);
    }

    function anySwapOutNative(address token, string memory to, uint toChainID) external payable {
        require(wNATIVE != address(0), "AnyswapV6Router: zero wNATIVE");
        require(AnyswapV1ERC20(token).underlying() == wNATIVE, "AnyswapV6Router: underlying is not wNATIVE");
        IwNATIVE(wNATIVE).deposit{value: msg.value}();
        assert(IwNATIVE(wNATIVE).transfer(token, msg.value));
        emit LogAnySwapOut(token, msg.sender, to, msg.value, cID(), toChainID);
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID
    function _anySwapIn(bytes32 txs, address token, address to, uint amount, uint fromChainID) internal {
        AnyswapV1ERC20(token).mint(to, amount);
        emit LogAnySwapIn(txs, token, to, amount, fromChainID, cID());
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID
    // triggered by `anySwapOut`
    function anySwapIn(bytes32 txs, address token, address to, uint amount, uint fromChainID) external onlyMPC {
        _anySwapIn(txs, token, to, amount, fromChainID);
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID with `to` receiving `underlying`
    function anySwapInUnderlying(bytes32 txs, address token, address to, uint amount, uint fromChainID) external onlyMPC {
        _anySwapIn(txs, token, to, amount, fromChainID);
        AnyswapV1ERC20(token).withdrawVault(to, amount, to);
    }

    // swaps `amount` `token` in `fromChainID` to `to` on this chainID with `to` receiving `underlying` if possible
    function anySwapInAuto(bytes32 txs, address token, address to, uint amount, uint fromChainID) external onlyMPC {
        _anySwapIn(txs, token, to, amount, fromChainID);
        AnyswapV1ERC20 _anyToken = AnyswapV1ERC20(token);
        address _underlying = _anyToken.underlying();
        if (_underlying != address(0) && IERC20(_underlying).balanceOf(token) >= amount) {
            if (_underlying == wNATIVE) {
                _anyToken.withdrawVault(to, amount, address(this));
                IwNATIVE(wNATIVE).withdraw(amount);
                TransferHelper.safeTransferNative(to, amount);
            } else {
                _anyToken.withdrawVault(to, amount, to);
            }
        }
    }

    function depositNative(address token, address to) external payable returns (uint) {
        require(wNATIVE != address(0), "AnyswapV6Router: zero wNATIVE");
        require(AnyswapV1ERC20(token).underlying() == wNATIVE, "AnyswapV6Router: underlying is not wNATIVE");
        IwNATIVE(wNATIVE).deposit{value: msg.value}();
        assert(IwNATIVE(wNATIVE).transfer(token, msg.value));
        AnyswapV1ERC20(token).depositVault(msg.value, to);
        return msg.value;
    }

    function withdrawNative(address token, uint amount, address to) external returns (uint) {
        require(wNATIVE != address(0), "AnyswapV6Router: zero wNATIVE");
        require(AnyswapV1ERC20(token).underlying() == wNATIVE, "AnyswapV6Router: underlying is not wNATIVE");

        uint256 old_balance = IERC20(wNATIVE).balanceOf(address(this));
        AnyswapV1ERC20(token).withdrawVault(msg.sender, amount, address(this));
        uint256 new_balance = IERC20(wNATIVE).balanceOf(address(this));
        assert(new_balance == old_balance + amount);

        IwNATIVE(wNATIVE).withdraw(amount);
        TransferHelper.safeTransferNative(to, amount);
        return amount;
    }

    // extracts mpc fee from bridge fees
    function anySwapFeeTo(address token, uint amount) external onlyMPC {
        address _mpc = mpc();
        AnyswapV1ERC20(token).mint(_mpc, amount);
        AnyswapV1ERC20(token).withdrawVault(_mpc, amount, _mpc);
    }

    function anySwapIn(bytes32[] calldata txs, address[] calldata tokens, address[] calldata to, uint256[] calldata amounts, uint[] calldata fromChainIDs) external onlyMPC {
        for (uint i = 0; i < tokens.length; i++) {
            _anySwapIn(txs[i], tokens[i], to[i], amounts[i], fromChainIDs[i]);
        }
    }
}