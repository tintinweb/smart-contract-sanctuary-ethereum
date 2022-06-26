/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract IdentityVerification {
    address private _owner;
    string[] verifiedIdentities;

    constructor ()  {
       _owner = msg.sender;
    }
    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function verify(string memory cid, bytes32 data, bytes32 hash) public payable returns (bool) {
        require(msg.value == 100000 gwei);
        if (sha256(abi.encodePacked(data)) == hash) {
            verifiedIdentities.push(cid);
        }
        return true;
    }

    // Withdraws all accumulate fees
    function withdrawFeeBalance() public onlyOwner returns (bool) {
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
}