// NFTStandard.sol
// SPDX-License-Identifier: MIT

/*
 * Error message map.
 * NS1 : client id array length must match the amount of tokens to be minted
 * NS2 : invalid client id #XYZ
 * NS3 : client id #XYZ is already minted
 * NS4 : get multi minting condition with nonexistent key
 * NS5 : beneficiary is not set
 * NS6 : no funds to withdraw
 * NS7 : failed to withdraw
 * NS8 : token id #XYZ does not exist
 * NS9 : token id #XYZ does not have its clientId
 * NS10 : URI query for nonexistent token
 * NS11 : the starting token id is greater than the ending token id
 * NS12 : royalty fee will exceed salePrice
 * NS13 : invalid receiver address
 * NS14 : invalid beneficiary address
 * NS15 : the starting block id is greater than the ending block
 * NS16 : maximum token amount per address can not be 0
 * NS17 : starting block has to be greater than current block height
 * NS18 : the starting client id is greater than the ending client id
 * NS19 : client id can not be 0
 * NS20 : given range contains minted token id
 * NS21 : given range overlaps a token range in minting condition ID #XYZ
 * NS22 : minting condition id #XYZ does not exist
 * NS23 : all tokens are minted
 * NS24 : the current block height is less than the starting block 
 * NS25 : insufficient funds
 * NS26 : it exceeds the remaining mintable tokens
 * NS27 : it exceeds the maximum token amount per address
 * NS28 : failed to refund
 * NS29 : not whitelisted
 * NS30 : invalid amount per address
 * NS31 : minting condition is closed already
 * NS32 : the current block height is greater than the ending block
*/

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Library for managing an enumerable minting condition
 * @dev inspired by Openzeppelin enumerable map
 */
library EnumerableSale {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Strings for uint256;
        
    // @dev a common struct to manage a range
    struct Range {
        uint256 _startId;
        uint256 _endId;
    }

    /**
     * @dev The minting condition struct
     * @param _tokenRange The token's id range that can be minted (inclusive).
     * @param _blockRange The block range where users can call the mint function(inclusive).
     * @param _clientIdRange The client id range mapped to the client-side resource (inclusive)
     * @param _minters the list of addresses to mint for airdrop
     * @param _whitelistMerkleRoot The merkle root calculated from the whitelist.
     * @param _price The token price in Wei.
     * @param _maxAmountPerAddress The maximum token amount that a single address can mint.
     * @param _baseuri The base URI of tokens in the specified range. It can be updated any time.
     * @param _royaltyReceiver The address to receive royalty of tokens in the specified range.
     * @param _royaltyFraction The royalty fraction to determine the royalty amount. It can be 
     * updated any time.
     */
    struct MintingConditionStruct {
        Range _tokenRange;
        Range _blockRange;
        Range _clientIdRange;
        address[] _minters;
        bytes32 _whitelistMerkleRoot;
        uint256 _price;
        uint256 _maximumAmountPerAddress;
        string _baseURI;
        address _royaltyReceiver;
        uint96 _royaltyFraction;
    }

    struct Sale {
        MintingConditionStruct _mintingCond;
        Counters.Counter _tokenIdTracker;
        bool _saleClosed;
        mapping(address => uint256) _tokensPerCapital;
    }

    struct Sales {
        uint256 _saleIdCounter;
        // Storage of keys
        EnumerableSet.UintSet _keys;
        mapping(uint256 => Sale) _values;
        EnumerableSet.UintSet _clientIdSet;
    }

    /**
     * @dev Add 1 to the number of token minted
     * @param key The sale/minting-condition Id
    */
    function _tokenTrackerIncrement(
        Sales storage sales,
        uint256 key
    ) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokenIdTracker.increment();
    }

    /**
     * @dev return the number of tokens minted
     * @param key The sale/minting-condition Id
    */
    function _tokenTrackerCurrent(
        Sales storage sales,
        uint256 key
    ) internal view returns(uint256) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._tokenIdTracker.current();
    }

    /**
     * @dev rest token tracker
     * @param key The sale/minting-condition Id
    */
    function _tokenTrackerReset(
        Sales storage sales,
        uint256 key
    ) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokenIdTracker.reset();
    }

    /**
     * @dev set flag CLOSED for sale
     * @param key The sale/minting-condition Id
     * @param state true: CLOSED, NOT CLOSED
    */
    function _setClosedState(
        Sales storage sales,
        uint256 key,
        bool state
    ) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._saleClosed = state;
    }

    /**
     * @dev check if sale is CLOSED or not
     * @param key The sale/minting-condition Id
    */
    function _getClosedState(
        Sales storage sales,
        uint256 key
    ) internal view returns(bool) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._saleClosed;
    }

    /**
     * @dev track whom minted how many tokens for commonValidation()
     * @param key The sale/minting-condition Id
    */
    function _setWhoMintedHowmany(
        Sales storage sales,
        uint256 key,
        address minter,
        uint256 amount
    ) internal {
        // assert key must exist
        assert(_contains(sales, key));
        sales._values[key]._tokensPerCapital[minter] = amount;
    }

    /**
     * @dev get whom minted how many tokens
     * @param key The sale/minting-condition Id
    */
    function _getWhoMintedHowmany(
        Sales storage sales,
        uint256 key,
        address minter
    ) internal view returns(uint256) {
        // assert key must exist
        assert(_contains(sales, key));
        return sales._values[key]._tokensPerCapital[minter];
    }
    
    /**
     * @dev check if a user is in the minter list or not
     * @param key The sale/minting-condition Id
    */
    function _isAMinter(
        Sales storage sales,
        uint256 key,
        address user
    ) internal view returns (bool){
        // assert key must exist
        assert(_contains(sales, key));
        address[] memory minters = sales._values[key]._mintingCond._minters;
        for (uint256 i = 0; i < minters.length; ++i) {
            if (user == minters[i]) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev function get the latest id created
    */
    function _getLatestSaleId(Sales storage sales) internal view returns(uint256) {
        return sales._saleIdCounter;
    }

    /**
     * @dev validate clientid
     * @param key The minting condition id
     * @param clientIds The client id list
     * @param amountPerAddress The amount to be minted for each address
     * @param receiversLenght The length of the NFT receivers
    */
    function _validateClientId(
        Sales storage sales,
        uint256 key,
        uint256[] calldata clientIds,
        uint256 amountPerAddress,
        uint256 receiversLenght
    ) internal {
        if (clientIds.length != 0) {
            // assert key must exist
            assert(_contains(sales, key));
            require(clientIds.length == (amountPerAddress * receiversLenght), "NS1");
            Range memory clidRange = sales._values[key]._mintingCond._clientIdRange;
            for (uint256 i = 0; i < clientIds.length; ++i) {
                uint256 clientId = clientIds[i];
                assert(clientId != 0); // must be != 0
                require(
                    (clientId >= clidRange._startId) && (clientId <= clidRange._endId), 
                    string(abi.encodePacked("NS2, ", clientId.toString()))
                );
                require(
                    sales._clientIdSet.add(clientId),
                    string(abi.encodePacked("NS3, ", clientId.toString()))
                );
            }
        }
    }

    /**
     * @dev calculate total tokens in a minting condition
    */
    function _totalToken(
        Sales storage sales,
        uint256 key
    ) internal view returns(uint256) {
        return (
            sales._values[key]._mintingCond._tokenRange._endId
            - sales._values[key]._mintingCond._tokenRange._startId + 1
        );
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing key.
     *
     * Returns true if the key was added to the map, that is if it was not already present.
     * @param key can be 0 or others. if 0 it creates new minting condition. If others it updates
     */
    function _set(
        Sales storage sales,
        uint256 key,
        MintingConditionStruct memory value
    ) internal returns (bool) {
        // if key = 0, create a new auto-incremented minting condition id
        if (key == 0) {
            ++sales._saleIdCounter; // omit #0
            key = _getLatestSaleId(sales);
        } else {
            assert(_contains(sales, key));
        }

        sales._values[key]._mintingCond = value;
        return sales._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     * @param key the sale/minting-condition id
     */
    function _remove(
        Sales storage sales,
        uint256 key
    ) internal returns (bool) {
        // assert key must exist
        assert(_contains(sales, key));
        delete sales._values[key];
        return sales._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     * @param key the sale/minting-condition id
     */
    function _contains(
        Sales storage sales,
        uint256 key
    ) internal view returns (bool) {
        return sales._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Sales storage sales) internal view returns (uint256) {
        return sales._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(
        Sales storage sales,
        uint256 index
    ) internal view returns (
        uint256,
        MintingConditionStruct memory
    ) {
        uint256 key = sales._keys.at(index);
        return (key, sales._values[key]._mintingCond);
    }


    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     * @param key the sale/minting-condition id
     */
    function _get(
        Sales storage sales,
        uint256 key
    ) internal view returns (MintingConditionStruct memory) {
        MintingConditionStruct memory value = sales._values[key]._mintingCond;
        require(_contains(sales, key), "NS4");
        return value;
    }
}

// abstract contract for NFT standard
abstract contract NFTStandard is 
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    IERC2981,
    Ownable,
    ReentrancyGuard {
    using EnumerableSale for EnumerableSale.Sales;
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    // @dev This emits when the minting condition is changed.
    event MintingConditionSet(
        uint256 _mintingConditionId,
        EnumerableSale.MintingConditionStruct _mintingCondition
    );

    // @dev This emits when the beneficiary who can withdraw the funds in the contract is set.
    event BeneficiarySet(address _beneficiary);

    // @dev This emits when the base URI is changed.
    event BaseURISet(
        EnumerableSale.Range _tokenRange,
        string _baseURI
    );

    // @dev This emits when the default royalty information is changed.
    event RoyaltyInfoSet(
        EnumerableSale.Range _tokenRange,
        address _receiver,
        uint96 _feeNumerator
    );

    // @dev This emits when the contract uri is changed.
    event ContractURISet(string _contractURI);

    // for multi minting condition management
    EnumerableSale.Sales private sales;

    // @dev mapping token id to client id
    mapping(uint256=>uint256) private tokenIdClientId;

    // @dev The version of this standard template
    uint256 public constant version = 3;

    // @dev public beneficiary address
    address payable public beneficiary;

    // @dev manage base uri by range
    struct Range_baseuri {
        EnumerableSale.Range _range;
        string _baseuri;
    }
    Range_baseuri[] private baseURIs;
    
    // @dev manage token royalty in range
    struct RoyaltyInfo {
        address _receiver;
        uint96 _royaltyFraction;
    }

    struct Range_royaltyinfo {
        EnumerableSale.Range _range;
        RoyaltyInfo _royalty;
    }
    Range_royaltyinfo[] private RoyaltyInfos;
    uint96 private immutable feeDenominator = 10000;

    // @dev record minted range
    EnumerableSale.Range[] private mintedRanges;

    // @dev reserved merkle root that allows for free-whitelist minting
    bytes32 private constant reservedMerkleRoot = 0x0;

    // @dev contract URI
    string private contractUri = "";
    
    /**
     * @dev Constructor
     * @notice The custom event is emitted for The Graph indexing service.
     * @param _name The name of the NFT token
     * @param _symbol The symbol of the NFT token
     * @param _contractUri The contract uri
    */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractUri
    ) ERC721(_name, _symbol) {
        setBeneficiary(_msgSender());
        setContractURI(_contractUri);
    }

    /**
     * @dev check if 2 ranges overlap each other
     * @param range1 the first range
     * @param range2 the second range
    */
    function overlapped(
        EnumerableSale.Range memory range1,
        EnumerableSale.Range memory range2
    ) private pure returns(bool) {
        // overlapped range is [overlapped_start, overlapped_stop] with:
        uint256 overlapped_start =
            (range1._startId >= range2._startId) ? range1._startId : range2._startId;
        uint256 overlapped_stop =
            (range1._endId <= range2._endId) ? range1._endId : range2._endId;
        return(overlapped_start <= overlapped_stop);
    }

    /**
     * @dev Check if comming range's vacant or not
     * @param _tokenRange The token id range to be verified
    */
    function isRangeVacant(EnumerableSale.Range memory _tokenRange) private view returns(bool) {
        EnumerableSale.Range[] memory rangesMinted = mintedRanges;
        for (uint i = 0; i < rangesMinted.length; ++i) {
            if (overlapped(_tokenRange, rangesMinted[i]))
                return false;
        }
        return true;
    }

    /**
     * @dev pause all transferring activities
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause all transferring activities
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Overriding just to solve a diamond problem.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(
        ERC721,
        ERC721Enumerable,
        IERC165
    ) returns (bool) {
        return interfaceId ==
            type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Withdraw the funds in this contract.
    */
    function withdraw() external onlyOwner {
        require(beneficiary != address(0x0), "NS5");
        require(address(this).balance > 0, "NS6");
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "NS7");
    }

    /**
     * @notice Return client ids mapped to given token ids
     * @dev Throws if any of given token ids is not minted.
     * @param _tokenIds Token ids to query client ids.
     * @return clientIds The array of client ids
    */
    function clientIdBatch(uint256[] calldata _tokenIds) external view returns (uint256[] memory) {
        uint256[] memory clientIds = new uint256[](_tokenIds.length);
        uint256 id;
        uint256 clid;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            id = _tokenIds[i];
            clid = tokenIdClientId[id];
            require(_exists(id), string(abi.encodePacked("NS8, ", id.toString())));
            require(clid != 0, string(abi.encodePacked("NS9, ", id.toString())));
            clientIds[i] = clid;
        }
        return clientIds;
    }

    /**
     * @notice Return the contract URI
     * @return contractUri The contract URI.
    */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Set the contract URI
     * @param _contractURI The contract URI to be set
    */
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractUri = _contractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NS10");
        string memory baseURI = _baseURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev overload ERC721::_baseURI() with tokenId as param
     * @param tokenId The baseURI of this tokenId will be returned
    */
    function _baseURI(uint256 tokenId) private view returns (string memory) {
        // scan backward to get the latest update on range baseuri
        Range_baseuri[] memory cachedBaseUris = baseURIs;
        for(uint256 idx = cachedBaseUris.length; idx > 0; idx--) {
            if (inRange(tokenId, cachedBaseUris[idx-1]._range)) {
                return cachedBaseUris[idx-1]._baseuri;
            }
        }
        return "";
    }

    /**
     * @dev private function to check if an ID is in range
     * @param _id The id to be verified if in range
     * @param _range The range to be verified if contains _id
    */
    function inRange(
        uint256 _id,
        EnumerableSale.Range memory _range
    ) private pure returns(bool) {
        return (_id >= _range._startId && _id <= _range._endId);
    }

    /**
     * @dev Change the base URI to apply to tokens in a specific range.
     * @param _tokenRange the token's id range that can be minted (inclusive).
     * @param _baseuri The base URI to set
    */
    function setBaseURI(
        EnumerableSale.Range calldata _tokenRange,
        string calldata _baseuri
    ) public onlyOwner {
        require(_tokenRange._startId <= _tokenRange._endId, "NS11");
        baseURIs.push(Range_baseuri(_tokenRange, _baseuri));
        emit BaseURISet(_tokenRange, _baseuri);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty;
        uint256 royaltyAmount;
        // scan backward to get the latest update on range royalty
        Range_royaltyinfo[] memory cachedRoyaltyInfos = RoyaltyInfos;
        for(uint256 idx = cachedRoyaltyInfos.length; idx > 0; idx--) {
            if (inRange(_tokenId, cachedRoyaltyInfos[idx-1]._range)) {
                royalty = cachedRoyaltyInfos[idx-1]._royalty;
                royaltyAmount = (_salePrice * royalty._royaltyFraction) / feeDenominator;
                return (royalty._receiver, royaltyAmount);
            }
        }
        return (address(0x0), 0);
    }

    /**
     * @dev Change the default royalty information to apply to tokens in a specific range.
     * @param _tokenRange he token's id range that can be minted (inclusive).
     * @param _receiver The account to receive royalty amount.
     * @param _feeNumerator The fee numerator to calculate royalty rate (numerator/feeDenominator).
    */
    function setRoyaltyInfo(
        EnumerableSale.Range calldata _tokenRange,
        address _receiver,
        uint96 _feeNumerator
    ) public onlyOwner {
        require(_tokenRange._startId <= _tokenRange._endId, "NS11");
        require(_feeNumerator <= feeDenominator, "NS12");
        require(_receiver != address(0), "NS13");
        RoyaltyInfos.push(Range_royaltyinfo(_tokenRange, RoyaltyInfo(_receiver, _feeNumerator)));
        emit RoyaltyInfoSet(_tokenRange, _receiver, _feeNumerator);
    }

    /**
     * @notice Set the beneficiary.
     * @param _beneficiary The beneficiary address to be set
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0x0), "NS14");
        beneficiary = payable(_beneficiary);
        emit BeneficiarySet(_beneficiary);
    }

    /**
     * @notice validate basic properties of a minting condition
     * @param _mintingCondition The minting condition to be validated
     */
    function commonValidation(
        EnumerableSale.MintingConditionStruct calldata _mintingCondition
    ) private view {
        require(
            _mintingCondition._tokenRange._startId <= _mintingCondition._tokenRange._endId,
            "NS11"
        );
        require(_mintingCondition._maximumAmountPerAddress != 0, "NS16");
        require(_mintingCondition._blockRange._startId > block.number, "NS17");
        require(
            _mintingCondition._clientIdRange._startId <= _mintingCondition._clientIdRange._endId,
            "NS18"
        );
        require(_mintingCondition._clientIdRange._startId > 0, "NS19");
    }

    /**
     * @notice Change the minting condition. Only the owner can change.
     * @dev If changed during a sale, only the ending of blockRange and whitelist are in effect.
     * @param _mintingConditionId 0 if creating; others(existing) if updating.
     * @param _mintingCondition The minting condition to be set for each sale
     */
    function setMintingCondition(
        uint256 _mintingConditionId,
        EnumerableSale.MintingConditionStruct calldata _mintingCondition
    ) external onlyOwner {
        require(
            _mintingCondition._blockRange._startId <= _mintingCondition._blockRange._endId,
            "NS15"
        );
        uint256 saleId;
        EnumerableSale.MintingConditionStruct memory sale;
        // validating the input minting condition vacancy and resolve valid overlapped configuration
        for (uint256 i = 0; i < sales._length(); ++i) {
            (saleId, sale) = sales._at(i);
            bool overlaping = overlapped(_mintingCondition._tokenRange, sale._tokenRange);

            // sale period expired
            if (block.number > sale._blockRange._endId) {
                if (!sales._getClosedState(saleId)) {
                    if(sales._tokenTrackerCurrent(saleId) != 0) {
                        // process to record minted Range
                        _closeSale(
                            saleId, 
                            EnumerableSale.Range(
                                sale._tokenRange._startId,
                                sale._tokenRange._startId + sales._tokenTrackerCurrent(saleId) - 1
                            ), 
                            true
                        );
                    } else if (overlaping) {
                        // totally unsatisfactory sale, allow for overlapping reconfiguration
                        sales._remove(saleId);
                    }
                }
            // in sale period
            } else if (block.number >= sale._blockRange._startId) {
                // sale is activated, prevent overlaping configuration creations
                if (_mintingConditionId == 0 && overlaping) {
                    revert(string(abi.encodePacked("NS21, ", saleId.toString())));
                }
            // in-the-future sales
            } else {
                // if sale hasn't started, allow for overllaping reconfiguration
                if (overlaping) {
                    sales._remove(saleId);
                }
            }
        }
        require(isRangeVacant(_mintingCondition._tokenRange), "NS20");
        
        // creating new minting condition
        if (_mintingConditionId == 0) {
            commonValidation(_mintingCondition);
            _newlySet(_mintingConditionId, _mintingCondition);
            emit MintingConditionSet(sales._getLatestSaleId(), _mintingCondition);
        // updating existing minting condition
        } else {
            require(
                sales._contains(_mintingConditionId),
                string(abi.encodePacked("NS22, ", _mintingConditionId.toString()))
            );
            require(!sales._getClosedState(_mintingConditionId), "NS31");
            // updating activated minting condition
            if (inRange(block.number, sales._get(_mintingConditionId)._blockRange)) {
                EnumerableSale.MintingConditionStruct memory newsaleInstance
                    = sales._get(_mintingConditionId);
                newsaleInstance._blockRange._endId = _mintingCondition._blockRange._endId;
                newsaleInstance._whitelistMerkleRoot
                    = _mintingCondition._whitelistMerkleRoot;
                newsaleInstance._minters = _mintingCondition._minters;
                sales._set(_mintingConditionId, newsaleInstance);
                setBaseURI(_mintingCondition._tokenRange, _mintingCondition._baseURI);
                setRoyaltyInfo(
                    _mintingCondition._tokenRange,
                    _mintingCondition._royaltyReceiver,
                    _mintingCondition._royaltyFraction
                );
                emit MintingConditionSet(_mintingConditionId, newsaleInstance);
            // updating inactivated minting condition
            } else {
                commonValidation(_mintingCondition);
                _newlySet(_mintingConditionId, _mintingCondition);
                emit MintingConditionSet(_mintingConditionId, _mintingCondition);
            }
        }
    }

    /**
     * @notice Set a minting condition newly
     * @param _mintingConditionId the minting condition id
     * @param _mintingCondition The minting condition to be set
     */
    function _newlySet(
        uint256 _mintingConditionId,
        EnumerableSale.MintingConditionStruct calldata _mintingCondition
    ) private {
        sales._set(_mintingConditionId, _mintingCondition);
        setBaseURI(_mintingCondition._tokenRange, _mintingCondition._baseURI);
        setRoyaltyInfo(
            _mintingCondition._tokenRange,
            _mintingCondition._royaltyReceiver,
            _mintingCondition._royaltyFraction
        );
    }

    /**
     * @notice Return the minting condition.
     * @param _mintingConditionId the minting condition id
     * @return a tuple of (Range, Range, Range, address[], bytes32, 
     * uint256, uint256, string, address, uint96)
     */
    function mintingCondition(
        uint256 _mintingConditionId
    ) external view returns (EnumerableSale.MintingConditionStruct memory) {
        return sales._get(_mintingConditionId);
    }

    /**
     * @notice Get all minting conditions id.
     * @return idBatch The array of all sale/minting condition ids
    */
    function mintingConditionIdBatch() external view returns (uint256[] memory) {
        uint256[] memory idBatch = new uint256[](sales._length());
        for (uint256 i = 0; i < sales._length(); ++i) {
            (idBatch[i], ) = sales._at(i);
        }
        return idBatch;
    }

    /**
    * @notice close and update infor + flag
    * @param _mintingConditionId The minting-condition/sale Id
    * @param _tokenRange The token range distributed (could be less than what's configured)
    */
    function _closeSale(
        uint256 _mintingConditionId,
        EnumerableSale.Range memory _tokenRange,
        bool _unsatisfactory
    ) private {
        mintedRanges.push(_tokenRange);
        sales._tokenTrackerReset(_mintingConditionId);
        sales._setClosedState(_mintingConditionId, true);
        // correct token range information if sale ended unsatisfactorily
        if (_unsatisfactory) {
            EnumerableSale.MintingConditionStruct memory newsaleInstance
                = sales._get(_mintingConditionId);
            newsaleInstance._tokenRange = _tokenRange;
            sales._set(_mintingConditionId, newsaleInstance);
        }
    }

    /**
     * @notice mint for receivers in batch
     * @param _mintingConditionId The minting-condition/sale id
     * @param _receivers The NFT receiver list
     * @param _amountPerEach The amount for each receiver
     * @param _clientIds The list of client Id
    */
    function _mint(
        uint256 _mintingConditionId,
        address[] memory _receivers,
        uint256 _amountPerEach,
        uint256[] memory _clientIds
    ) private {
        uint256 tokenId;
        // receivers list shouldn't be too big
        for(uint256 i = 0; i < _receivers.length; ++i) {
            for(uint256 j = 0; j < _amountPerEach; ++j) {
                tokenId = sales._get(_mintingConditionId)._tokenRange._startId
                    + sales._tokenTrackerCurrent(_mintingConditionId);
                _safeMint(_receivers[i], tokenId);
                sales._tokenTrackerIncrement(_mintingConditionId);
                if (_clientIds.length != 0) {
                    tokenIdClientId[tokenId] = _clientIds[_amountPerEach*i + j];
                }
            }
        }
    }

    /**
     * @notice refund
     * @param fund The fund
    */
    function _refund(uint256 fund) private {
        if (fund != 0) {
            (bool sent, ) = payable(_msgSender()).call{value: fund}("");
            require(sent, "NS28");
        }
    }

    /**
     * @notice The minted tokens belong to msg.sender if whitelist mode enabled and belongs to receivers
     * if minters mint.
     * The remaining coin after minting is refunded.
     * @dev Mint the token with the native coin.
     *
     * @param _mintingConditionId The id given by the contract for each successful minting condition set
     * @param _receivers The list to receve NFT when minters mint
     * @param _amountPerAddress The number of tokens to mint
     * @param _clientIds An array of clientIds that should be a subset of mintingCondition.clientIdRange.
     * @param _merkleProof The proof that msg.sender is in the whitelist.
     */
    function mint(
        uint256 _mintingConditionId,
        address[] calldata _receivers,
        uint256 _amountPerAddress,
        uint256[] calldata _clientIds,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(_amountPerAddress != 0, "NS30");
        require(
            sales._contains(_mintingConditionId),
            string(abi.encodePacked("NS22, ", _mintingConditionId.toString()))
        );
        require(!sales._getClosedState(_mintingConditionId), "NS23");
        EnumerableSale.MintingConditionStruct memory sale = sales._get(_mintingConditionId);
        require(sale._blockRange._startId <= block.number, "NS24");
        require(block.number <= sale._blockRange._endId, "NS32");

        uint256 tokenNumPC;
        // validate minters and mint to receivers if minters make the call
        if(sale._minters.length != 0
            && sales._isAMinter(_mintingConditionId, _msgSender())
            && (_receivers.length > 0)
        ) {
            require(msg.value >= (sale._price * _amountPerAddress * _receivers.length), "NS25");
            require(
                sales._tokenTrackerCurrent(_mintingConditionId) + _amountPerAddress * _receivers.length
                    <= sales._totalToken(_mintingConditionId),
                "NS26"
            );
            for (uint256 i = 0; i < _receivers.length; ++i) {
                tokenNumPC = sales._getWhoMintedHowmany(_mintingConditionId, _receivers[i]);
                require((tokenNumPC + _amountPerAddress) <= sale._maximumAmountPerAddress, "NS27");
            }
            sales._validateClientId(_mintingConditionId, _clientIds, _amountPerAddress, _receivers.length);

            _mint(_mintingConditionId, _receivers, _amountPerAddress, _clientIds);

            // record amount of tokens per person
            for (uint256 i = 0; i < _receivers.length; ++i) {
                tokenNumPC = sales._getWhoMintedHowmany(_mintingConditionId, _receivers[i]);
                sales._setWhoMintedHowmany(_mintingConditionId, _receivers[i], tokenNumPC + _amountPerAddress);
            }

            // all tokens in range have been minted
            if (sales._tokenTrackerCurrent(_mintingConditionId) == sales._totalToken(_mintingConditionId)) {
                _closeSale(_mintingConditionId, sale._tokenRange, false);
            }

            _refund(msg.value - (sale._price * _amountPerAddress * _receivers.length));

        //validate whitelist program and mint to caller
        } else {
            if (sale._whitelistMerkleRoot != reservedMerkleRoot) {
                bytes32 merkleLeaf = keccak256(abi.encodePacked(_msgSender()));
                require(MerkleProof.verify(_merkleProof, sale._whitelistMerkleRoot, merkleLeaf), "NS29");
            }

            require(msg.value >= (sale._price * _amountPerAddress), "NS25");
            require(
                sales._tokenTrackerCurrent(_mintingConditionId) + _amountPerAddress
                    <= sales._totalToken(_mintingConditionId),
                "NS26"
            );
            tokenNumPC = sales._getWhoMintedHowmany(_mintingConditionId, _msgSender());
            require((tokenNumPC + _amountPerAddress) <= sale._maximumAmountPerAddress, "NS27");
            sales._validateClientId(_mintingConditionId, _clientIds, _amountPerAddress, 1);

            address[] memory user = new address[](1);
            user[0] = _msgSender();
            _mint(_mintingConditionId, user, _amountPerAddress, _clientIds);
            sales._setWhoMintedHowmany(_mintingConditionId, _msgSender(), tokenNumPC + _amountPerAddress);
            
            // all tokens in range have been minted
            if (sales._tokenTrackerCurrent(_mintingConditionId) == sales._totalToken(_mintingConditionId)) {
                _closeSale(_mintingConditionId, sale._tokenRange, false);
            }

            _refund(msg.value - (sale._price * _amountPerAddress));
        }
    }
}

contract CanNFTStandard is NFTStandard {
    constructor(string memory _name, string memory _symbol, string memory _contractUri)
        NFTStandard(_name, _symbol, _contractUri) {
        // do nothing
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}