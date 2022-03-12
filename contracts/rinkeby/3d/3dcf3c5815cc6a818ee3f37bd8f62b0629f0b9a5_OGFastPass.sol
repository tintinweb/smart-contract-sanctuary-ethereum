// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC1155.sol";
import "Ownable.sol";
import "Pausable.sol";
import "MerkleProof.sol";

contract OGFastPass is ERC1155, Ownable, Pausable {

    bytes32 merkleRoot;
    string merkleUri;
    uint8 merkleProofDepth;
    uint8 currentSupply;
    uint8 maxSupply = 233;
    bool bypassMerkle;

    constructor() ERC1155("") {}

    function enableProof(bool enable) public onlyOwner {
        bypassMerkle = !enable;
    }

    function setMerkle(bytes32 root, uint8 depth, string memory newuri) public onlyOwner {
        merkleRoot = root;
        merkleProofDepth = depth;
        merkleUri = newuri;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function getMerkleUri() public view returns(string memory) {
       return merkleUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintPass(uint256 id, bytes32[] calldata proof) public {
        address account = _msgSender();
        require(
            bypassMerkle || 
            (proof.length >= merkleProofDepth - 1 && proof.length <= merkleProofDepth && 
                MerkleProof.processProof(
                    proof, 
                    keccak256(abi.encodePacked(account))) == merkleRoot
            ), 
            "Invalid proof"
        );
        uint8 amount = 1;
        require(balanceOf(account, id) < amount && currentSupply + amount <= maxSupply, "No more pass available");
        _mint(account, id, amount, "");
        currentSupply += amount;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}