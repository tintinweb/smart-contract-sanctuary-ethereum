// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IERC721Factory.sol";
import "./ERC721YuanChuang.sol";

contract ERC721Factory is IERC721Factory {

    mapping(string => address) private _metadata;

    function createERC721(string memory _name,string memory _symbol,string memory _primaryKey) external override returns(address erc721) {
        bytes memory bytecode = type(ERC721YuanChuang).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol,_primaryKey));
        assembly {
            erc721 := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ERC721YuanChuang(erc721).initialize(_name, _symbol,msg.sender);
        _metadata[_primaryKey] = erc721;
        emit ERC721Created(_name, _symbol, erc721);
    }

    function erc721ContractAddr(string memory _primaryKey) external view override returns(address) {
        address _addr = _metadata[_primaryKey];
        return _addr;
    }

}