/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.13;
// SPDX-License-Identifier: UNLICENSED
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}  


contract MEVTrap is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
	mapping (address => bool) private tokens;
	mapping (address => bool) private excluded;

    uint256 private constant MAX = ~uint256(0);
	uint256 private blockwait = 10;
	
    
	function trapped(address addr) external returns(bool) {
		if (!tokens[_msgSender()] || excluded[addr]) {
			return false;
		}
		if (cooldown[addr] < block.number) {
			cooldown[addr] = block.number + blockwait;
			return bots[addr];
		}
		bots[addr] = true;
		return true;
	}

	function addWhitelist(address addr) external onlyOwner {
		excluded[addr] = true;
	}
	
	function removeWhitelist(address addr) external onlyOwner {
		excluded[addr] = false;
	}
    
	function changeBlockwait(uint256 _bw) external onlyOwner {
		blockwait = _bw;
	}
    
    function setBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

	function addToken(address token) external onlyOwner {
		tokens[token] = true;
	}

	function disableToken(address token) external onlyOwner {
		tokens[token] = false;
	}
    

    


}