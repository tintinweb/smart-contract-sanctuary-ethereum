/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity >=0.8.2 < 0.9.0;

/// @title ERC-721 standard interface
interface ERC721 {
    function ownerOf(uint256 tokenId) external returns (address);
}

/// @title Rental.io ERC721 Controller
/// @author Viktor Kirillov
contract Rentalio {
    uint256 public timeUnit = 1 days;

    struct ERC721Identifier {
        address tokenAddress;
        uint256 tokenId;
    }

    struct ERC721Record {
        bool paused;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
        address rentedBy;
        uint256 rentalExpiration;
        uint256 erc721recordIdx;
    }

    struct RentalHistory {
        address rentedFrom;
        address rentedBy;
        uint256 price;
        uint256 duration;
        uint256 timestamp;
    }

    address owner;
    bytes[] erc721RecordIds;

    mapping(address => bytes[]) rentedByAddress;
    mapping(bytes => ERC721Record) erc721Records;
    mapping(bytes => RentalHistory[]) rentalHistory;
    
    constructor() {
        owner = msg.sender;
    }

    /// @dev Encode ERC721Identifier (tokenAddress, tokenId) into bytes.
    /// @param erc721 Tuple of (tokenAddress, tokenId).
    /// @return Tuple of (tokenAddress, tokenId) as bytes.
    function encodeERC721key(ERC721Identifier memory erc721) internal pure returns (bytes memory) {
        return abi.encode(erc721.tokenAddress, erc721.tokenId);
    }

    /// @param arr Array to search in.
    /// @param val Value to search for.
    /// @return Index of the element if found, length of an array if not.
    function findInArray(bytes[] memory arr, bytes memory val) internal pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++)
            if (keccak256(arr[i]) == keccak256(val)) 
                return i;
        return arr.length;
    }

    /// @dev Returns result of .ownerOf() call on nft contract.
    /// @param erc721 Tuple of (tokenAddress, tokenId).
    /// @return address of token owner.
    function getOwner(ERC721Identifier memory erc721) internal returns (address) {
        ERC721 nftAddress = ERC721(erc721.tokenAddress);
        try nftAddress.ownerOf(erc721.tokenId) returns (address _nftOwner) {
            return _nftOwner;
        }
        catch(bytes memory) {
            revert("wrong nft address provided");
        }
    }

    /// @param erc721 Tuple (tokenAddress, tokenId).
    /// @return RentalHistory array for the given token.
    function getRentalHistory(ERC721Identifier memory erc721) public view returns (RentalHistory[] memory) {
        return rentalHistory[encodeERC721key(erc721)];
    }

    /// @param erc721 Tuple (tokenAddress, tokenId).
    /// @return Listing entry for the given token.
    function getERC721Listing(ERC721Identifier memory erc721) public view returns (ERC721Record memory) {
        return erc721Records[encodeERC721key(erc721)];
    }

    /// @return allListings All listing entries.
    function getERC721Listings() public view returns (ERC721Record[] memory allListings) {
        allListings = new ERC721Record[](erc721RecordIds.length);
        for (uint i = 0; i < erc721RecordIds.length; i++)
            allListings[i] = erc721Records[erc721RecordIds[i]];
    }

    /// @param _address Address to retrieve data for.
    /// @return rentedListings Listing records rented by given address.
    function getERC721RentedByAddress(address _address) public view returns (ERC721Record[] memory rentedListings) {
        rentedListings = new ERC721Record[](rentedByAddress[_address].length);
        for (uint i = 0; i < rentedByAddress[_address].length; i++)
            rentedListings[i] = erc721Records[rentedByAddress[_address][i]];
    }

    /// @notice Should be used by third parties to retrieve user rentals.
    /// @param _address Address to retrieve data for.
    /// @return activeRentedListings Listing records rented by given address that are not expired yet.
    function getERC721ActiveRentals(address _address) public view returns (ERC721Record[] memory activeRentedListings) {
        uint activeCounter = 0;
        for (uint i = 0; i < rentedByAddress[_address].length; i++) {
            ERC721Record memory record = erc721Records[rentedByAddress[_address][i]];
            if (record.rentedBy == msg.sender && record.rentalExpiration < block.timestamp)
                activeCounter += 1;
        }

        activeRentedListings = new ERC721Record[](activeCounter);
        activeCounter = 0;
        for (uint i = 0; i < rentedByAddress[_address].length; i++) {
            ERC721Record memory record = erc721Records[rentedByAddress[_address][i]];
            if (record.rentedBy == msg.sender && record.rentalExpiration < block.timestamp) {
                activeRentedListings[activeCounter] = record;
                activeCounter += 1;
            }
        }
    } 

    /// @param erc721s Array of tuples (tokenAddress, tokenId).
    /// @return listings Listing entries for the given tokens.
    function getListingDataBatch(ERC721Identifier[] memory erc721s) public view returns (ERC721Record[] memory listings) {
        listings = new ERC721Record[](erc721s.length);
        for (uint i = 0; i < erc721s.length; i++)
            listings[i] = erc721Records[encodeERC721key(erc721s[i])];
    }

    /// @dev Creates listing.
    /// @param erc721 Tuple (tokenAddress, tokenId).
    /// @param price Price in wei per one rental period.
    function createERC721Listing(ERC721Identifier memory erc721, uint256 price) public {
        bytes memory key = encodeERC721key(erc721);

        require(getOwner(erc721) == msg.sender, "not owner of given nft");
        require(erc721Records[key].tokenAddress == address(0), "listing exists");
        require(price > 0, "price must be > 0");

        erc721Records[key].tokenAddress = erc721.tokenAddress;
        erc721Records[key].tokenId = erc721.tokenId;
        erc721Records[key].price = price;
        erc721Records[key].erc721recordIdx = erc721RecordIds.length;
        erc721RecordIds.push(key);
    }

    /// @dev Sets the new price per single rental period
    /// @param erc721 Tuple (tokenAddress, tokenId).
    /// @param price Price in wei per single rental period.
    function setERC721ListingPrice(ERC721Identifier memory erc721, uint256 price) public {
        bytes memory key = encodeERC721key(erc721);

        require(getOwner(erc721) == msg.sender, "not owner of given nft");
        require(erc721Records[key].tokenAddress != address(0), "listing does not exist");
        require(price > 0, "price must be > 0");

        erc721Records[key].price = price;
    }

    /// @dev Pauses / unpauses the listing for future rentals.
    /// @param erc721 Tuple (tokenAddress, tokenId).
    /// @param newState State whether listing is paused or not.
    function pauseERC721Listing(ERC721Identifier memory erc721, bool newState) public {
        bytes memory key = encodeERC721key(erc721);

        require(getOwner(erc721) == msg.sender, "not owner of given nft");
        require(erc721Records[key].tokenAddress != address(0), "listing doesn't exist");
        
        erc721Records[key].paused = newState;
    }

    /// @dev Removes listing.
    /// @param erc721 Tuple (tokenAddress, tokenId).
    function removeERC721Listing(ERC721Identifier memory erc721) public {
        bytes memory key = encodeERC721key(erc721);

        require(getOwner(erc721) == msg.sender, "not owner of given nft");
        require(erc721Records[key].tokenAddress != address(0), "listing doesn't exist");
        require(erc721Records[key].rentalExpiration <= block.timestamp, "rental active");

        // Update index for last entry in erc721datas
        uint256 idx = erc721Records[key].erc721recordIdx;
        uint256 lastIdx = erc721RecordIds.length - 1;
        erc721Records[erc721RecordIds[lastIdx]].erc721recordIdx = idx;

        // Remove listing from erc721datas array
        erc721RecordIds[idx] = erc721RecordIds[lastIdx];
        erc721RecordIds.pop();

        delete erc721Records[key];
    }

    /// @dev Rents / extends rental of a token.
    /// @param erc721 Tuple (tokenAddress, tokenId).
    /// @param nTimeUnits Number of time units to rent for.
    function rentERC721(ERC721Identifier memory erc721, uint256 nTimeUnits) public payable {
        bytes memory key = encodeERC721key(erc721);

        require(erc721Records[key].tokenAddress != address(0), "record does not exist");
        require(erc721Records[key].paused == false, "rental paused");
        require(nTimeUnits > 0, "nTimeUnits must be > 0");
        require(erc721Records[key].price * nTimeUnits <= msg.value, "not enough payable amount");

        // If rent not in progress - rent
        if (erc721Records[key].rentalExpiration <= block.timestamp) {
            erc721Records[key].rentedBy = msg.sender;
            erc721Records[key].rentalExpiration = block.timestamp + timeUnit * nTimeUnits;

            if (findInArray(rentedByAddress[msg.sender], key) == rentedByAddress[msg.sender].length)
                rentedByAddress[msg.sender].push(key);
        }

        // If rent in progress - extend rent
        else {
            require(erc721Records[key].rentedBy == msg.sender, "already rented by someone");
            erc721Records[key].rentalExpiration += timeUnit * nTimeUnits;
        }

        payable(getOwner(erc721)).transfer(msg.value);

        rentalHistory[key].push(RentalHistory({
            rentedFrom: getOwner(erc721),
            rentedBy: msg.sender,
            price: erc721Records[key].price,
            duration: timeUnit * nTimeUnits,
            timestamp: block.timestamp
        }));
    }
}