/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    mapping(address => bool) _allowed;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
        _allowed[_msgSender()] = true;
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function toggleAllowed(address _addr) public onlyOwner {
    	_allowed[_addr] = !_allowed[_addr];
    }

    modifier onlyAllowed() {
    	require(_allowed[_msgSender()], "Ownable: only allowed");
    	_;
    }

   
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

  
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

  
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract whiteListing is Ownable {
	mapping(address => bool) _whitelist;


	function isWhitelisted(address _addr) external view returns(bool){
		return _whitelist[_addr];
	}

	function addToWhitelist(address _addr) external onlyAllowed {
		_whitelist[_addr] = true;
	}

    function addBatchToWhitelist(address[] memory _addr) external onlyAllowed {
        for(uint256 i=0; i<_addr.length; i++){
            _whitelist[_addr[i]] = true;
        }
    }

	function removeFromWhitelist(address _addr) external onlyAllowed {
		_whitelist[_addr] = false;
	}
}