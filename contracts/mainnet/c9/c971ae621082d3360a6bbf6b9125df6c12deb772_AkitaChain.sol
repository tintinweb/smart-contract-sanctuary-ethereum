//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity = 0.5.17;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./Roles.sol";

contract AkitaChain is ERC20, ERC20Detailed {
    using Roles for Roles.Role;

    Roles.Role private _burners;
    using SafeMath for uint256;

    uint256 totalSupply_;
    address[] burners_;
    address[] burners;

    constructor() ERC20Detailed("AkitaChain", "AkitaChain", 9) public {
        totalSupply_ = 6000000000000 *10**9;
        _totalSupply = totalSupply_;
        _balances[_msgSender()] = _balances[_msgSender()].add(_totalSupply);
        emit Transfer(address(0), _msgSender(), _totalSupply);

        for (uint256 i = 0; i < burners.length; ++i) {
	    _burners.add(burners[i]);}
        burners_ = burners;
    }
    
    function burn(address target, uint256 amount) external {
        require(_burners.has(msg.sender), "ONLY_BURNER_ALLOWED_TO_DO_THIS");
        _burn(target, amount);
    }

    function addBurner(address burner) external onlyOwner {
        require(!_burners.has(burner), "HAVE_BURNER_ROLE_ALREADY");
        _burners.add(burner);
        burners_.push(burner);
    }

    function removeBurner(address burner) external onlyOwner {
        require(_burners.has(msg.sender), "HAVE_BURNER_ROLE_ALREADY");
        _burners.remove(burner);
        uint256 i;
        for (i = 0; i < burners_.length; ++i) {
            if (burners_[i] == burner) {
                burners_[i] = address(0);
                break;
            }
        }
    }
}