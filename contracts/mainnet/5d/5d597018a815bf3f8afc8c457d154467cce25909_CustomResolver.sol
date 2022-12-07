// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ENS.sol";
import "./IRollupProcessor.sol";
import "./AddrResolver.sol";

interface INameWrapper {
    function ownerOf(uint256 id) external view returns (address);
}

contract CustomResolver is 
    AddrResolver 
{
    ENS immutable ens;
    IRollupProcessor immutable rollupProcessor;
    INameWrapper immutable nameWrapper;

    /**
     * A mapping of operators. An address that is authorised for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (owner, operator) => approved
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Logged when someone sends to Aztec using sendPrivate()
    event SendToAztec(
        address indexed from,
        address indexed to,
        uint value
    );
    
    constructor(
        ENS _ens,
        IRollupProcessor _rollupProcessor,
        INameWrapper wrapperAddress
    ) {
        ens = _ens;
        rollupProcessor = _rollupProcessor;
        nameWrapper = wrapperAddress;
    }

    /**
     * Re-direct the funds to Aztec's RollupProcessor where the receiver can claim using Aztec protocol.
     */
    function sendPrivate(bytes32 node)
        external
        payable
    {
        require(
            isSendPrivate(node) == true,
            "Private sends are not enabled for this name."
        );
        address receiver = addr(node);

        require(
            receiver != address(0),
            "No address associated with this ENS name."
        );

        rollupProcessor.depositPendingFunds{value: msg.value}(0, msg.value, receiver, bytes32(0));
        emit SendToAztec(msg.sender, receiver, msg.value);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        address owner = ens.owner(node);
        if (owner == address(nameWrapper)) {
            owner = nameWrapper.ownerOf(uint256(node));
        }
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            AddrResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}