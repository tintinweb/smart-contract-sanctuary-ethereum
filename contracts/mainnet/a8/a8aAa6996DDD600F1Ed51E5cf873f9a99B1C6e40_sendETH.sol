/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract sendETH {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }

    // function sendETHAdminWallet(address _address) public payable {
    //     uint256 _amount = address(this).balance;
    //     (bool success, ) = _address.call{value: _amount}("");
    //     require(success, "Failed to withdraw Ether");
    // }
    function sendETHPerWallet(address[] memory addresses, uint256 amount)
        public
        payable
        onlyOwner
    {
        require(msg.value >= addresses.length * amount, "Insufficient fund");
        bool success;
        for (uint256 i = 0; i < addresses.length; i++) {
            (success, ) = addresses[i].call{value: amount}("");
            require(success, "Failed to withdraw Ether");
        }
        uint256 _amount = address(this).balance;
        (success, ) = _owner.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function withdraw() public onlyOwner {
        uint256 _amount = address(this).balance;
        (bool success, ) = _owner.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");
    }
}