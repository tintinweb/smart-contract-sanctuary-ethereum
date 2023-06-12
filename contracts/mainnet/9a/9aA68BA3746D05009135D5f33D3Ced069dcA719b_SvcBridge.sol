// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function owner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address account, uint256 amount) external;
}

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract SvcBridge {
    event Deposit(address indexed token, address indexed from, uint256 amount, uint256 targetChain);
    event Transfer(bytes32 indexed txId, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    mapping(address => bool) public isPeggingToken;
    mapping(address => bool) public isToken;
    mapping(bytes32 => bool) public exists;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    receive() external payable {}

    function addTokens(address[] memory tokens) external onlyOwner {
        for (uint256 k = 0; k < tokens.length; k++) {
            isToken[tokens[k]] = true;
        }
    }

    function deposit(address target, address token, uint256 amount, uint256 targetChain) external payable {
        require(msg.sender.code.length == 0, 'bridge: only personal');
        require(msg.sender != address(0) && target != address(0), 'bridge: zero sender');
        if (token == address(0)) {
            require(msg.value == amount, 'bridge: amount');
        } else {
            require(isToken[token], 'token does not supported');
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        }

        emit Deposit(token, target, amount, targetChain);
    }

    function transfer(uint256[][] memory args) external payable onlyOwner {
        for (uint256 i = 0; i < args.length; i++) {
            address _token = address(uint160(args[i][0]));
            address _to = address(uint160(args[i][1]));
            uint256 _amount = args[i][2];
            bytes32 _extra = bytes32(args[i][3]);
            if (!exists[_extra]) {
                if (_token == address(0)) {
                    TransferHelper.safeTransferETH(_to, _amount);
                } else {
                    require(isToken[_token], 'token does not supported');
                    TransferHelper.safeTransfer(_token, _to, _amount);
                }
                exists[_extra] = true;
                emit Transfer(_extra, _amount);
            }
        }
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}