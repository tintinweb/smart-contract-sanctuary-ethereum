/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
// This contract is not supposed to be used in production
// It's strictly for testing purpose


pragma solidity ^0.8.3;


import "ERC1155Burnable.sol";
import "IMintableERC1155.sol";
import "NativeMetaTransaction.sol";
import "ContextMixin.sol";
import "AccessControlMixin.sol";
import "ERC1155.sol";





contract NFT1155Testing is ERC1155Burnable, AccessControlMixin, NativeMetaTransaction, ContextMixin, IMintableERC1155 {

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    string private _name;
    string private _symbol;




    constructor()  ERC1155("DNFT") {
        _setupContractId("NFT1155Testing");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());

    _name ="TESTDDNFT";
    _symbol = "DDNFT";
        _initializeEIP712(_name);
    }




    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

   function _msgSender()
        internal
        override
        view
        returns (address  sender)
    {
        return ContextMixin.msgSender();
    }
}