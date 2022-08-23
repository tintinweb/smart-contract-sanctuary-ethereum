// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SudoInu.sol";

contract WrappedXminu is ERC20 {

    uint256 DECIMAL_MULTIPLIER = 1e18;

    SudoInu public immutable XMINU;

    event NFTDeposit(address indexed from, address indexed to, uint256 indexed amount);
    event NFTWithdrawal(address indexed from, address indexed to, uint256 indexed amount);

    constructor(SudoInu _xminu) ERC20("Wrapped Sudo Inu", "WXMINU", 18) {
        XMINU = _xminu;
    }

    function deposit(address to, uint256[] calldata nftIds) public {        
        for (uint256 i; i < nftIds.length; ) {
            XMINU.transferFrom(msg.sender, address(this), nftIds[i]);

            unchecked {
                ++i;
            }
        }

        _mint(to, nftIds.length * DECIMAL_MULTIPLIER);
   
        emit NFTDeposit(msg.sender, to, nftIds.length);
   }

    function withdraw(address to, uint256[] calldata nftIds) public {
        for (uint256 i; i < nftIds.length; ) {
            XMINU.transferFrom(address(this), to, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        _burn(msg.sender, nftIds.length * DECIMAL_MULTIPLIER);

        emit NFTWithdrawal(msg.sender, to, nftIds.length);
    }
}