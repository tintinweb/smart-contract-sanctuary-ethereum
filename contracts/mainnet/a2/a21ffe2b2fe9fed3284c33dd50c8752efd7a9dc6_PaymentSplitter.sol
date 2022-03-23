/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

contract PaymentSplitter is Ownable {
    address payable[] public partners;
    uint256[] public shares;

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function changePartners(address payable[] memory newPartners, uint256[] memory newShares) public onlyOwner {
        delete partners;
        delete shares;
        uint256 length = newPartners.length;
        require(newPartners.length == newShares.length, "number of new partners must match number of new shares");
        for(uint256 i=0; i<length; i++) {
            partners.push(newPartners[i]);
            shares.push(newShares[i]);
        }
    }

    function getTotalShares() public view returns (uint256) {
        uint256 totalShares;
        uint256 length = partners.length;
        for (uint256 i = 0; i<length; i++) {
            totalShares += shares[i];
    }
      return totalShares;
  }

    function withdraw() public payable {
        address partner;
        uint256 share;
        uint256 totalShares = getTotalShares();
        uint256 length = partners.length;
        uint256 balanceBeforeWithdrawal = address(this).balance;
        for (uint256 j = 0; j<length; j++) {
            partner = partners[j];
            share = shares[j];

            (bool success, ) = partner.call{value: balanceBeforeWithdrawal * share/totalShares}("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }
    }

}