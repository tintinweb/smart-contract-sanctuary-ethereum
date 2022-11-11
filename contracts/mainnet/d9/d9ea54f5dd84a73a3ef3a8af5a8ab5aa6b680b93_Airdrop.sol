/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address to) external;
}


contract Airdrop {
    address public owner;
    IERC721 public NFTs;
    mapping(address => bool) members;

    /**
     * @dev Emitted when set air drop NFTs contract.
     */
    event SetNFTContract(address nftContract); 
    
    /**
     * @dev Emitted when set member.
     */
    event SetMember(address account,bool result); 

    /**
     * @dev Emitted when air drop is completed.
     */
    event AirdropNFTs(uint256 count); 

    /**
     * @dev Grants owner to the account that deploys the contract.
     */
    constructor () {
        owner = msg.sender;
    }

    /**
     * @dev Grants owner to the account that deploys the contract.
     */
    modifier OnlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier OnlyMember(){
        require(members[msg.sender]);
        _;
    }

    /**
     * @dev Set air drop NFTs contract.
     *
     * Requirements:
     *
     * - the caller must have the `Owner`.
     * - `nftContract` cannot be the zero address.
     */
    function setNFTContract(address nftContract) external OnlyOwner() {
        NFTs = IERC721(nftContract);
        emit SetNFTContract(nftContract);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasMember(address account) public view virtual returns (bool) {
        return members[account];
    }

    /**
     * @dev Set member to operation air drop account.
     *
     * Requirements:
     *
     * - the caller must have the `Owner`.
     * - `account` cannot be the zero address.
     */
    function setMember(address account) external OnlyOwner() {
        members[account] = true;
        emit SetMember(account,true);
    }

    /**
     * @dev Remove member to operation air drop account.
     *
     * Requirements:
     *
     * - the caller must have the `Owner`.
     * - `account` cannot be the zero address.
     */
    function removeMember(address account) external OnlyOwner() {
        members[account] = false;
        emit SetMember(account,false);
    }


    /**
     * @dev Air drop NFTs to `tos`.
     *
     * Requirements:
     *
     * - the caller must have the `Members`.
     * - `tos` cannot be the zero address.
     */
    function airDropMint(address[] calldata tos) external OnlyMember() {
        for (uint256 i; i < tos.length; i++) {
            NFTs.mint(tos[i]);
        }
        emit AirdropNFTs(tos.length);
    }
}