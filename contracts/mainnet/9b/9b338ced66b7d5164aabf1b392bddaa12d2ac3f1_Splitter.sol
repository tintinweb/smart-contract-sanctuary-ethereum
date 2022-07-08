/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

}

contract Splitter {

    uint256 internal constant IS_NOT_LOCKED = uint256(1);
    uint256 internal constant IS_LOCKED = uint256(2);

    uint256 internal _lockedStatus = IS_NOT_LOCKED;

    address[3] public accounts;

    constructor(address[3] memory accounts_) {
        accounts[0] = accounts_[0];
        accounts[1] = accounts_[1];
        accounts[2] = accounts_[2];
    }

    modifier noReenter() {
        require(_lockedStatus == IS_NOT_LOCKED, "NO_REENTER");

        _lockedStatus = IS_LOCKED;
        _;
        _lockedStatus = IS_NOT_LOCKED;
    }

    function changeAccount(uint256 index_, address account_) external {
        require(accounts[index_] == msg.sender, "UNAUTHORIZED");
        accounts[index_] = account_;
    }

    function splitETH() external noReenter {
        uint256 totalBalance = address(this).balance;

        // NOTE: we don't care about success. If it fails, that account loses out on that portion.
        //       Leftover funds will get re-split next call.
        _transferEth(accounts[0], (totalBalance * 70) / 100);
        _transferEth(accounts[1], (totalBalance * 15) / 100);
        _transferEth(accounts[2], (totalBalance * 15) / 100);
    }

    function splitToken(address token_) external noReenter {
        uint256 totalBalance = IERC20(token_).balanceOf(address(this));

        // NOTE: We don't care about success. If it fails, that account loses out on that portion.
        //       Leftover funds will get re-split next call.
        IERC20(token_).transfer(accounts[0], (totalBalance * 70) / 100);
        IERC20(token_).transfer(accounts[1], (totalBalance * 15) / 100);
        IERC20(token_).transfer(accounts[2], (totalBalance * 15) / 100);
    }

    function _transferEth(address destination_, uint256 amount_) internal returns (bool success_) {
        ( success_, ) = destination_.call{value: amount_}("");
    }

    receive() payable external {}

    fallback() payable external {}

}