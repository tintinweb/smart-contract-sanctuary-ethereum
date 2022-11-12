/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address to, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Controllable {
	address internal _owner;
	mapping(address => bool) internal _managers;

	constructor() {
		_owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}
	
	modifier onlyManagers() {
		require(msg.sender == _owner || _managers[msg.sender]);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
		}
	}
	
	function addManager(address manager) public onlyManagers {
		if (manager != address(0)) {
			_managers[manager] = true;
		}
	}
	
	function delManager(address manager) public onlyManagers {
		if (manager != address(0)) {
			_managers[manager] = false;
		}
	}

	function getOwner() public view returns (address) {
		return _owner;
	}
	
	function isManagers(address _address) public view returns (bool) {
		return _managers[_address];
	}

}

contract SmartWallet is Controllable {

	bool internal _initialized;
	
	receive()  external payable {}
	fallback() external payable {}

	function initialize(address newOwner) public {
		require(!_initialized);
		require(newOwner != address(0));
		_owner = newOwner;
		_initialized = true;
	}
	
	function coinTransfer(address payable _to, uint256 _value) public onlyManagers {
      bool sent = _to.send(_value);
      require(sent, "Failed to send Ether");
	}
	
	function tokenTransfer(IERC20 _token, address _to, uint256 _value) public onlyManagers {
		_token.transfer(_to, _value);
	}

    function tokenApprove(IERC20 _token, address _spender, uint256 _value) public onlyManagers {
		_token.approve(_spender, _value);
	}

    function transferFrom(IERC20 _token, address _from, address _to, uint256 _value) public onlyManagers {
		_token.transferFrom(_from, _to, _value);
	}

    function batchCoinTransfer(address payable[] calldata _to, uint256[] calldata _value) public onlyManagers {		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
		  bool sent = _to[i].send(_value[i]);
          require(sent, "Failed to send Ether");
			unchecked {++i;}
		}
	}

    function batchTokenTransfer(
		IERC20[] calldata _token,
		address[] calldata _to,
		uint256[] calldata _value
	) public onlyManagers {		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
			_token[i].transfer(_to[i], _value[i]);
			unchecked {++i;}
		}
	}

    function batchTokenApprove(
		IERC20[] calldata _token,
		address[] calldata _spender,
		uint256[] calldata _value
	) public onlyManagers {		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
			_token[i].approve(_spender[i], _value[i]);
			unchecked {++i;}
		}
	}

    function batchTransferFrom(
		IERC20[] calldata _token,
		address[] calldata _from,
		address[] calldata _to,
		uint256[] calldata _value
	) public onlyManagers {
		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
			_token[i].transferFrom(_from[i], _to[i], _value[i]);
			unchecked {++i;}
		}
	}

    function batchCoinTokenTransfer(
		address payable[] calldata _CoinTo,
		uint256[] calldata _CoinValue,
		IERC20[] calldata _token,
		address[] calldata _TokenTo,
		uint256[] calldata _TokenValue
	) public onlyManagers {
		uint len = _CoinValue.length;
		for (uint8 i=0; i < len;) {
            bool sent = _CoinTo[i].send(_CoinValue[i]);
            require(sent, "Failed to send Ether");
            unchecked {++i;}
			}
		len = _TokenValue.length;
		for (uint8 i=0; i < len;) {
			_token[i].transfer(_TokenTo[i], _TokenValue[i]);
			unchecked {++i;}
		}
	}

    function batchCoinTransferTransferFrom(
		address payable[] calldata _CoinTo,
		uint256[] memory _CoinValue,
		IERC20[] calldata _token,
		address[] calldata _TokenFrom,
		address[] calldata _TokenTo,
		uint256[] calldata _TokenValue
	) public onlyManagers {
		uint len = _CoinValue.length;
		for (uint8 i=0; i < len;) {
			bool sent = _CoinTo[i].send(_CoinValue[i]);
            require(sent, "Failed to send Ether");
			unchecked {++i;}
			}
		len = _TokenValue.length;
		for (uint8 i=0; i < len;) {
			_token[i].transferFrom(_TokenFrom[i], _TokenTo[i], _TokenValue[i]);
			unchecked {++i;}
		}
	}

    function batchTokenTransferTransferFrom(
		IERC20[] calldata _tokenTransfer,
		address[] memory _TokenTransferTo,
		uint256[] memory _TokenTransferValue,
		IERC20[] calldata _tokenTrFrom,
		address[] calldata _TokenTrFromFrom,
		address[] calldata _TokenTrFromTo,
		uint256[] memory _TokenTrFromValue
	) public onlyManagers {
		uint len = _TokenTransferValue.length;

		for (uint8 i=0; i < len;) {
			_tokenTransfer[i].transfer(_TokenTransferTo[i], _TokenTransferValue[i]);
			unchecked {++i;}
		}
		len = _TokenTrFromValue.length;
		for (uint8 i=0; i < len;) {
			_tokenTrFrom[i].transferFrom(_TokenTrFromFrom[i], _TokenTrFromTo[i], _TokenTrFromValue[i]);
			unchecked {++i;}
		}
	}

    function batchCoinTokenTransferTransferFrom(
		address payable[] memory _CoinTo,
		uint256[] memory _CoinValue,
		IERC20[] calldata _tokenTransfer,
		address[] memory _TokenTransferTo,
		uint256[] memory _TokenTransferValue,
		IERC20[] calldata _tokenTrFrom,
		address[] memory _TokenTrFromFrom,
		address[] memory _TokenTrFromTo,
		uint256[] memory _TokenTrFromValue
	) public onlyManagers {
		uint len = _CoinValue.length;
		for (uint8 i=0; i < len;) {
			bool sent = _CoinTo[i].send(_CoinValue[i]);
            require(sent, "Failed to send Ether");
			unchecked {++i;}
			}
		len = _TokenTransferValue.length;

		for (uint8 i=0; i < len;) {
			_tokenTransfer[i].transfer(_TokenTransferTo[i], _TokenTransferValue[i]);
			unchecked {++i;}
		}
		len = _TokenTrFromValue.length;
		for (uint8 i=0; i < len;) {
			_tokenTrFrom[i].transferFrom(_TokenTrFromFrom[i], _TokenTrFromTo[i], _TokenTrFromValue[i]);
			unchecked {++i;}
		}
	}
    
}