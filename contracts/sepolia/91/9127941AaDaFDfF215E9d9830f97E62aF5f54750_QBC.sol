// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./BlackListable.sol";

contract QBC is ERC20, BlackListable{

    //50%锁定
    address private account1 = 0x98F4F6c4a20fa415d30829D1e1C058ceaCA82a54;
    //5%扶贫钱包
    address private account2 = 0xa4ae0d2507472AFc94220A449E0627Abddf9fd74;
    //3%用于CEX
    address private account3 = 0x1Dc6dD81968A851177c30E8CCa657eaD9Eaeddda;
    //2%用于营销推广
    address private account4 = 0x1927Ad42552ad8271d48FeEcB3D0028f1E25FC01;
    //40%底池
    address private account5 = 0x356f3819d6A57394DC6e74A50106d518E7a422bF;

    uint8 private accountCount = 0;

    constructor() ERC20("Fixed", "FIX") {
        uint256 total = 10000000000000 * (10 ** 8);
        _mint(account1, total / uint256(2));
        _mint(account2, total / uint256(20));
        _mint(account3, total * uint256(3) / uint256(100));
        _mint(account4, total / uint256(50));
        _mint(account5, total * uint256(2) / uint256(5));
    }

    function _beforeTokenTransfer(
        address from,
        address to
    ) override internal virtual {
        require( from != account1);

        require(!isBlackListed[to] && !isBlackListed[from], "Blacklisted");
    }

    function _afterTokenTransfer(
        address from,
        address to
    ) override internal virtual {

        if (balanceOf(from) > 0 && balanceOf(to) > 0 && to != address(0)) {
            accountCount++;
        }

        if(accountCount == 1000 || accountCount == 2000){
            _burn(from, totalSupply() / uint256(20));
        }
        if(accountCount == 3000 || accountCount == 5000){
            _burn(from, totalSupply() / uint256(10));
        }
        if(accountCount == 10000){
            _burn(from, totalSupply() / uint256(5));
        }
    }
}