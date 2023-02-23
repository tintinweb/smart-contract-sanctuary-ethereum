// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPublicResolver {
    // function setAddr(bytes32 node, uint256 coinType) external;
    function setAddr(bytes32 node, address addr) external;
}

interface IRegistrar {
    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract RentManager {
    // making them public for now, maybe change it to private
    IRegistrar public registrar;
    IPublicResolver public publicResolver =
        IPublicResolver(0x19c2d5D0f035563344dBB7bE5fD09c8dad62b001);

    // we need to get the _nftAddress of the ENS from somewhere
    constructor(address _registrarAddress) {
        registrar = IRegistrar(_registrarAddress);
        // maybe in the future change the IERC721 interface to IBaseRegistrar interface
    }

    // struct to keep the data on renters and their period
    struct Rental {
        address renter;
        uint256 rentEndTime;
    }

    mapping(bytes32 => Rental) public ensRentals;
    mapping(address => bytes32[]) public ownerEnses;

    // call safeTransferFrom
    // give: from (address), to (address) and tokenId (uint256)
    function callSafeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        registrar.safeTransferFrom(from, to, tokenId);
    }

    // sets the address in the records book to _addr
    // potentially a function that will be used to set the renters address, so he could use it
    function callSetAddr(bytes32 _node, address _addr) external {
        publicResolver.setAddr(_node, _addr);
    }

    // call this function to give the ens to the initialOwner, only the owner can call this
    // should call the reclaim function and change it to initialOwner
    // function liquidate

    // call reclaim
    // give: tokenId (uint256) and owner (address)
    function callReclaim(uint256 tokenId, address to) external {
        registrar.reclaim(tokenId, to);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    // function _myIsApprovedOrOwner(
    //     address spender,
    //     uint256 tokenId
    // ) internal view returns (bool) {
    //     address owner = ownerOf(tokenId);
    //     return (spender == owner &&
    //         getApproved(tokenId) == spender &&
    //         isApprovedForAll(owner, spender));
    // }
}