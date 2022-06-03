// SPDX-License-Identifier: MIT
// AlphaClub.VIP Bulk Transfer Contract (https://github.com/alphaclubvip/contracts/AlphaClub001.sol)
//
// Visit: https://AlphaClub.VIP/bulk

pragma solidity =0.8.14;

import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20Metadata.sol";

contract AlphaClub001 is Context {
    using SafeMath for uint256;
    uint256 private _triggers;
    uint256 private _transfers;
    address payable private _author = payable(0x88884B1dd7A941F832F1574f3E124235f3Ba8888);

    event Donation(address indexed account, uint256 amount);

    function read() public view returns (address payable author, uint256 triggers, uint256 transfers) {
        author = _author;
        triggers = _triggers;
        transfers = _transfers;
    }

    function readERC20(address _token, address _account) public view returns (string memory name, string memory symbol, uint8 decimals, uint256 balance, uint256 allowance) {
        IERC20Metadata TOKEN = IERC20Metadata(_token);

        name = TOKEN.name();
        symbol = TOKEN.symbol();
        decimals = TOKEN.decimals();
        balance = TOKEN.balanceOf(_account);
        allowance = TOKEN.allowance(_account, address(this));
    }

    function bulkTransfer(address payable [] calldata _recipients, uint256[] calldata _amounts) public payable {
        require(_recipients.length <= 200, "transfers exceed  200");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(_amounts[i]);
        }

        _transfer(_recipients.length);
        _donate();
    }

    function bulkTransferSame(address payable [] calldata _recipients, uint256 _amount) public payable {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(_amount);
        }

        _transfer(_recipients.length);
        _donate();
    }

    function bulkTransferERC20(address _token, address[] calldata _recipients, uint256[] calldata _amounts) public payable {
        require(_recipients.length <= 200, "transfers exceed  200");

        require(_recipients.length == _amounts.length);

        IERC20 TOKEN = IERC20(_token);
        address _sender = _msgSender();

        for (uint256 i = 0; i < _recipients.length; i++) {
            assert(TOKEN.transferFrom(_sender, _recipients[i], _amounts[i]));
        }

        _transfer(_recipients.length);
        _donate();
    }

    function bulkTransferERC20Same(address _token, address[] calldata _recipients, uint256 _amount) public payable {
        require(_recipients.length <= 200, "transfers exceed  200");

        IERC20Metadata TOKEN = IERC20Metadata(_token);
        address _sender = _msgSender();

        for (uint256 i = 0; i < _recipients.length; i++) {
            assert(TOKEN.transferFrom(_sender, _recipients[i], _amount));
        }

        _transfer(_recipients.length);
        _donate();
    }

    receive() external payable {
        _donate();
    }

    function _donate() private {
        uint256 _balance = address(this).balance;
        if (0 < _balance) {
            _author.transfer(_balance);
            emit Donation(_msgSender(), _balance);
        }
    }

    function _transfer(uint256 count) private {
        _triggers = _triggers.add(1);
        _transfers = _transfers.add(count);
    }
}