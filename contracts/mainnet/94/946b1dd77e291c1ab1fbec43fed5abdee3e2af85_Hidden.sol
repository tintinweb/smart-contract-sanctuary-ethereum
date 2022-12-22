/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
interface Kudasai {
    function kantsuCounter() external view returns (uint256);
}

contract Hidden {
    address private immutable _kudasai;
    string private _salt;
    constructor(string memory salt_, address kudasai_) {
        _salt = salt_;
        _kudasai = kudasai_;
    }

    function check(address _to, uint256 _quantity, bytes32 _code) public view returns (bool) {
        if (_code == _HHH(_to, _quantity)) {
            return true;
        } else {
            return false;
        }
    }
    function _HHH(address _to, uint256 _quantity) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _quantity, _salt, Kudasai(_kudasai).kantsuCounter()));
    }
}