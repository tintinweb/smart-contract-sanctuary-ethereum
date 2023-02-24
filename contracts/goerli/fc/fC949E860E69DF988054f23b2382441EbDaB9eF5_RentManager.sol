// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

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

/**
 * @title RentManager should implement ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract RentManager is IERC721Receiver {
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
    struct Listing {
        uint256 rentPrice;
        uint256 rentPeriod;
    }
    // also figure out a way how to store the original registrants, so we could check who is calling the "giveBack" function and give it back.

    mapping(uint256 => Rental) public ensRentals;
    mapping(uint256 => Listing) public ensListings;
    mapping(address => uint256[]) public ownerEnses;
    mapping(uint256 => address) public originalOwners;

    // this functions should be called only from the script.ts, but need to figue out how to check, otherwise it's an attack vector
    function setOriginalOwner(uint256 tokenId) external {
        // need to be checked!
        originalOwners[tokenId] = msg.sender;
    }

    function createListing(
        uint256 tokenId,
        uint256 rentPrice,
        uint256 rentPeriod
    ) external {
        // checks to be done ...abi
        require(msg.sender == originalOwners[tokenId], "You are not the owner");
        // set the ensListings mapping
        ensListings[tokenId] = Listing(rentPrice, rentPeriod);
        // set the ensRentals mapping to address(0), aka not rented by anyone yet
        ensRentals[tokenId].renter = address(0);
    }

    // rent function
    // give: tokenId(uint256) and msg.value that is bigger than rentPrice
    function rent(uint256 tokenId) external payable {
        // check if the ens is already rented
        require(
            ensRentals[tokenId].renter == address(0),
            "This ENS is already rented"
        );
        // check if the renter has enough balance
        require(
            msg.value >= ensListings[tokenId].rentPrice,
            "The amount you sent is not enough"
        );
        // other checks ...

        // set the ensRentals mapping
        ensRentals[tokenId] = Rental(
            msg.sender,
            block.timestamp + ensListings[tokenId].rentPeriod * 1 days
        );
        // set the ownerEnses mapping
        ownerEnses[msg.sender].push(tokenId);
        // transfer the rentPrice to the owner
        payable(msg.sender).transfer(ensListings[tokenId].rentPrice);
        // transfer the ens to the renter
        registrar.reclaim(tokenId, msg.sender);
    }

    // TODO: function liquidate

    // this function should be called ONLY when the rent ends and we want to return the registrant back to the original owner.
    // call safeTransferFrom
    // give: from (address), to (address) and tokenId (uint256)
    function giveBack(uint256 tokenId) external {
        registrar.safeTransferFrom(
            address(this),
            originalOwners[tokenId],
            tokenId
        );
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        // Handle the ERC721 token received here
        // The function must return the ERC721_RECEIVED value to confirm that the transfer was successful
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}