/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract MultiTransfer {
	event OwnershipRenounced(address indexed previousOwner);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	address public owner;
	mapping(address=>bool) public admins;

	constructor(address _admin) {
		owner = msg.sender;
		admins[_admin] = true;
	}

	modifier onlyAdmin() {
		require(admins[msg.sender] || msg.sender == owner);
		_;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	receive() external payable {}

	function setAdmin(address _address, bool _isAdmin) public onlyOwner {
		if (_isAdmin) {
			admins[_address] = true;
		} else {
			admins[_address] = false;
		}
	}

	function transferOwnership(address newOwner) public onlyAdmin {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}

	function renounceOwnership() public onlyOwner {
		emit OwnershipRenounced(owner);
		owner = address(0);
	}
 	function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function transfer(uint[][] memory params) external payable onlyAdmin {
		for(uint i=0; i<params.length; i++) {
			address _token 		= address(uint160(params[i][0]));
			address _to			= address(uint160(params[i][1]));
			uint _amount 		= params[i][2];
			if (_token==address(0)) {
				payable(_to).transfer(_amount);
			} else {
				safeTransfer(_token, _to, _amount);
			}
		}
	}
}