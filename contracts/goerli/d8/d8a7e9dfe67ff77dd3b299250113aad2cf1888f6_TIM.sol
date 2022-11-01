// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

contract TIM is ERC1155, ERC1155Burnable, Ownable {
    constructor() ERC1155("") {}

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);

        // Ensure the operator can trans tokens on behalf of owners since gas fee is consumed from operator
        _checkAndSetApprovedForAll(account);

    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);

        // Ensure the operator can trans tokens on behalf of owners since gas fee is consumed from operator
        _checkAndSetApprovedForAll(to);
    }



    function _checkAndSetApprovedForAll(address owner)
        internal
        onlyOwner
    {
        // Ensure the operator can trans tokens on behalf of owners since gas fee is consumed from operator
        if(!isApprovedForAll(owner,_msgSender()))
        {
            _setApprovalForAll(owner, _msgSender(), true);
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override 
    {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        _checkAndSetApprovedForAll(to);
    }

}