/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// File: contracts/Rentalio.sol


pragma solidity ^0.8.0;

interface ERC721 {
    function ownerOf(uint256 tokenId) external returns(address);
}

contract Rentalio {

    struct ERC721Record {
        bool paused;

        address tokenAddress;
        uint256 tokenId;
        uint256 price;

        address rentedBy;
        uint256 rentalExpiration;

        uint256 erc721recordIdx;
    }

    struct ERC721Identifier {
        address tokenAddress;
        uint256 tokenId;
    }

    struct RentalHistory {
        address rentedFrom;
        address rentedBy;
        uint256 price;
        uint256 duration;
    }

    uint256 public timeUnit = 30 seconds;
    
    bytes[] erc721RecordIds;
    mapping(bytes => ERC721Record) public erc721Records;

    address[] DEBUG_rentedByAddressKeys;
    mapping(address => bytes[]) public rentedByAddress;

    mapping(bytes => RentalHistory[]) public rentalHistory;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    // For debug purposes
    function deleteAll() public {
        require(msg.sender == owner, "not owner");

        for (uint256 i = 0; i < erc721RecordIds.length; i++) {
            delete erc721Records[erc721RecordIds[i]];
            delete rentalHistory[erc721RecordIds[i]];
        }
        delete erc721RecordIds;

        for (uint256 i = 0; i < DEBUG_rentedByAddressKeys.length; i++) {
            delete rentedByAddress[DEBUG_rentedByAddressKeys[i]];
        }
        delete DEBUG_rentedByAddressKeys;
    }

    // For debug purposes
    function setTimeUnit(uint256 _timeUnit) public {
        require(msg.sender == owner, "not owner");
        timeUnit = _timeUnit;
    }

    function encodeERC721key(ERC721Identifier memory erc721) public pure returns (bytes memory) {
        return abi.encode(erc721.tokenAddress, erc721.tokenId);
    }

    function decodeERC721key(bytes memory key) public pure returns (ERC721Identifier memory) {
        (ERC721Identifier memory erc721) = abi.decode(key, (ERC721Identifier));
        return erc721;
    }

    function findInArray(bytes[] memory arr, bytes memory value) internal pure returns (uint256) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (keccak256(arr[i]) == keccak256(value)) 
                return i;
        }
        return arr.length;
    }

    function getRentalHistory(ERC721Identifier memory erc721) public view returns (RentalHistory[] memory) {
        return rentalHistory[encodeERC721key(erc721)];
    }

    function getERC721Listing(ERC721Identifier memory erc721) public view returns (ERC721Record memory) {
        return erc721Records[encodeERC721key(erc721)];
    }

    // Return all ERC721Record[] listings
    function getERC721Listings() public view returns (ERC721Record[] memory) {
        ERC721Record[] memory result = new ERC721Record[](erc721RecordIds.length);
        for (uint i = 0; i < erc721RecordIds.length; i++) {
            result[i] = erc721Records[erc721RecordIds[i]];
        }
        return result;
    }

    // Return all ERC721Record[] nfts rented by address
    function getERC721RentedByAddress(address _address) public view returns (ERC721Record[] memory) {
        ERC721Record[] memory result = new ERC721Record[](rentedByAddress[_address].length);
        for (uint i = 0; i < rentedByAddress[_address].length; i++) {
            result[i] = erc721Records[rentedByAddress[_address][i]];
        }
        return result;
    }

    
    function getListingData(ERC721Identifier memory erc721) public view returns (ERC721Record memory) {
        return erc721Records[encodeERC721key(erc721)];
    }

    // Returns bool[] whether nfts are listed or not
    function getListingDataBatch(ERC721Identifier[] memory erc721s) public view returns (ERC721Record[] memory) {
        ERC721Record[] memory result = new ERC721Record[](erc721s.length);
        for (uint i = 0; i < erc721s.length; i++) {
            result[i] = getListingData(erc721s[i]);
        }
        return result;
    }

    function getOwner(ERC721Identifier memory erc721) internal returns(address) {
        ERC721 nftAddress = ERC721(erc721.tokenAddress);
        try nftAddress.ownerOf(erc721.tokenId) returns (address _nftOwner) {
            return _nftOwner;
        }
        catch(bytes memory) {
            revert("wrong nft address provided");
        }
    }

    function verifyERC721Owner(ERC721Identifier memory erc721) internal {
        require(getOwner(erc721) == msg.sender, "not owner of given nft");
    }

    function createERC721Listing(ERC721Identifier memory erc721, uint256 price) public {
        verifyERC721Owner(erc721);
        bytes memory key = encodeERC721key(erc721);

        require(erc721Records[key].tokenAddress == address(0), "listing exists");
        require(price > 0, "price must be > 0");

        erc721Records[key].tokenAddress = erc721.tokenAddress;
        erc721Records[key].tokenId = erc721.tokenId;
        erc721Records[key].price = price;
        erc721Records[key].erc721recordIdx = erc721RecordIds.length;
        erc721RecordIds.push(key);
    }

    function setERC721ListingPrice(ERC721Identifier memory erc721, uint256 price) public {
        verifyERC721Owner(erc721);
        bytes memory key = encodeERC721key(erc721);

        require(erc721Records[key].tokenAddress == address(0), "listing exists");
        require(price > 0, "price must be > 0");

        erc721Records[key].price = price;
    }

    function pauseERC721Listing(ERC721Identifier memory erc721, bool newState) public {
        verifyERC721Owner(erc721);
        bytes memory key = encodeERC721key(erc721);

        require(erc721Records[key].tokenAddress != address(0), "listing doesn't exist");
        
        erc721Records[key].paused = newState;
    }

    function removeERC721Listing(ERC721Identifier memory erc721) public {
        verifyERC721Owner(erc721);
        bytes memory key = encodeERC721key(erc721);

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

    function rentERC721(ERC721Identifier memory erc721, uint256 nTimeUnits) public payable {
        bytes memory key = encodeERC721key(erc721);

        require(erc721Records[key].tokenAddress != address(0), "record does not exist");
        require(erc721Records[key].paused == false, "rental paused");

        require(nTimeUnits > 0, "nTimeUnits must be > 0");
        require(erc721Records[key].price * nTimeUnits <= msg.value, "not enough payable amount");

        // If rent not in progress
        if (erc721Records[key].rentalExpiration <= block.timestamp) {
            erc721Records[key].rentedBy = msg.sender;
            erc721Records[key].rentalExpiration = block.timestamp + timeUnit * nTimeUnits;
            if (findInArray(rentedByAddress[msg.sender], key) == rentedByAddress[msg.sender].length) {
                DEBUG_rentedByAddressKeys.push(msg.sender);
                rentedByAddress[msg.sender].push(key);

                rentalHistory[key].push(RentalHistory({
                    rentedFrom: getOwner(erc721),
                    rentedBy: msg.sender,
                    price: erc721Records[key].price,
                    duration: timeUnit * nTimeUnits
                }));
            }
        }
        else {
            if (erc721Records[key].rentedBy == msg.sender) {
                erc721Records[key].rentalExpiration += timeUnit * nTimeUnits;

                rentalHistory[key].push(RentalHistory({
                    rentedFrom: getOwner(erc721),
                    rentedBy: msg.sender,
                    price: erc721Records[key].price,
                    duration: timeUnit * nTimeUnits
                }));
            }
            else {
                revert("already rented by someone");
            }
        }
    }

    function blockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}