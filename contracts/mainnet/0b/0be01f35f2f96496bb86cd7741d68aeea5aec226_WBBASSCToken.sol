// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./4_ERC20.sol";
import "./6_Pausable.sol";
import "./5_ownable.sol";

contract WBBASSCToken is ERC20, Pausable, Ownable {

    

    constructor() ERC20("WBBASSC", "WBBASSC") {
       
        _mint(0xfc0A694F4e43a5B851Cd3af5dA1127C9A32828dC, 100000000000000 * 10 ** decimals()); // 100 trillion
        _mint(0x716603D8717163d6Bad9eb65cE853c80663509A1, 100000000000000 * 10 ** decimals());
        _mint(0x544B19642D0209158C9b10c5003873801D01aBf8, 100000000000000 * 10 ** decimals());
        _mint(0x4FBF051a82Afc04A5f0FeBA4fc8bAc91d19D1bc3, 100000000000000 * 10 ** decimals());
        _mint(0x240288107303b5d8facB78902dFc950004cC5463, 100000000000000 * 10 ** decimals());
        _mint(0x3e424f0f91A3C6371715A3d568c400F07eaffc41, 100000000000000 * 10 ** decimals());
        _mint(0x8C3008723aF7a9F3B7dd23c968a8252924c5dF2C, 100000000000000 * 10 ** decimals());
        _mint(0xdec968f0342F9F0d8e187fF57430ddB3D6c83aF0, 100000000000000 * 10 ** decimals());
        _mint(0x4373fbB9D88ac14F8FFa62e6eDdADE326098baD9, 100000000000000 * 10 ** decimals());
        _mint(0xC76F71C1D8659F7e4f26d081a8074A9c4e65A520, 99425000000000 * 10 ** decimals()); // 99trillion 425 billion
        _mint(0xa1838B8C7Df8c17F48a8abea2899D0ab070F53bc, 575000000000 * 10 ** decimals()); // 575 billion
           


    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

   
}