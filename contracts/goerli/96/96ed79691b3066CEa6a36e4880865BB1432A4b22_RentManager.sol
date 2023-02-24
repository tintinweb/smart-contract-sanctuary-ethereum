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

    mapping(uint256 => Rental) public ensRentals;
    mapping(address => uint256[]) public ownerEnses;

    // call safeTransferFrom
    // give: from (address), to (address) and tokenId (uint256)
    function callSafeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        registrar.safeTransferFrom(from, to, tokenId);
    }

    // rent function
    // give: tokenId(uint256), rentPrice(uint256) and rentPeriod(uint256)
    function rent(
        uint256 tokenId,
        uint256 rentPrice,
        uint256 rentPeriod
    ) external {
        // check if the ens is already rented
        require(
            ensRentals[tokenId].renter == address(0),
            "This ENS is already rented"
        );
        // check if the renter has enough balance
        require(
            msg.sender.balance >= rentPrice,
            "You don't have enough balance"
        );
        // other checks ...

        // set the ensRentals mapping
        ensRentals[tokenId] = Rental(
            msg.sender,
            block.timestamp + rentPeriod * 1 days
        );
        // set the ownerEnses mapping
        ownerEnses[msg.sender].push(tokenId);
        // transfer the rentPrice to the owner
        payable(msg.sender).transfer(rentPrice);
        // transfer the ens to the renter
        registrar.reclaim(tokenId, msg.sender);
    }

    // call this function to give the ens to the initialOwner, only the owner can call this
    // should call the reclaim function and change it to initialOwner
    // function liquidate

    // call reclaim
    // give: tokenId (uint256) and owner (address)
    function callReclaim(uint256 tokenId, address to) external {
        registrar.reclaim(tokenId, to);
    }

    receive() external payable {}
}