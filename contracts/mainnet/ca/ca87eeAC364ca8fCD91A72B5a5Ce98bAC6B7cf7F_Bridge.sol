/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
	function owner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);

	function mintTo(address account, uint256 amount) external;
	function burnFrom(address account, uint256 amount) external;
}

library TransferHelper {
	function safeTransfer(address token, address to, uint value) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
	}

	function safeTransferFrom(address token, address from, address to, uint value) internal {
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
	}

	function safeTransferETH(address to, uint value) internal {
		(bool success,) = to.call{value:value}(new bytes(0));
		require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
	}
}

contract Bridge {
	event Deposit(address indexed token, address indexed from, uint amount, uint targetChain);
	event Transfer(bytes32 indexed txId, uint amount);
	
	address public immutable owner;
	address public immutable admin;

	mapping(address=>bool) public isPeggingToken;
	mapping(address=>bool) public isToken;
	mapping(bytes32=>bool) public exists;

	constructor(address _admin) {
		owner = msg.sender;
		admin = _admin;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}
	modifier onlyAdmin() {
		require(msg.sender == admin || msg.sender == owner);
		_;
	}

	receive() external payable {}

	// function addTokens(address[] memory tokens) external onlyAdmin {
	// 	for (uint k=0; k<tokens.length; k++) {
	// 		if (IERC20(tokens[k]).owner()==address(this)) {
	// 			isPeggingToken[tokens[k]] = true;
	// 		} else {
	// 			isToken[tokens[k]] = true;
	// 		}
	// 	}
	// }

	function addPeggingTokens(address[] memory tokens) external onlyAdmin {
		for (uint k=0; k<tokens.length; k++) {
			require(IERC20(tokens[k]).owner()==address(this), "Bridge: pegging token owner");
			isPeggingToken[tokens[k]] = true;
		}
	}

	function addTokens(address[] memory tokens) external onlyAdmin {
		for (uint k=0; k<tokens.length; k++) {
			isToken[tokens[k]] = true;
		}
	}

	function deposit(address target, address token, uint amount, uint targetChain) external payable {
		require(msg.sender.code.length==0, "bridge: only personal");
		require(msg.sender!=address(0) && target!=address(0), "bridge: zero sender");
		if (token==address(0)) {
			require(msg.value==amount, "bridge: amount");
		} else {
			if (isPeggingToken[token]) {
				IERC20(token).burnFrom(msg.sender, amount);
			} else if (isToken[token]){
				TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
			} else {
				revert();
			}
		}
		emit Deposit(token, target, amount, targetChain);
	}

	function transfer(uint[][] memory args) external payable onlyAdmin {
		for(uint i=0; i<args.length; i++) {
			address _token 		= address(uint160(args[i][0]));
			address _to			= address(uint160(args[i][1]));
			uint _amount 		= args[i][2];
			bytes32 _extra 		= bytes32(args[i][3]);
			if (!exists[_extra]) {
				if (_token==address(0)) {
					TransferHelper.safeTransferETH(_to, _amount);
				} else {
					if (isPeggingToken[_token]) {
						IERC20(_token).mintTo(_to, _amount);
					} else if (isToken[_token]) {
						TransferHelper.safeTransfer(_token, _to, _amount);
					}
				}
				exists[_extra] = true;
				emit Transfer(_extra, _amount);
			}
		}
	}
}