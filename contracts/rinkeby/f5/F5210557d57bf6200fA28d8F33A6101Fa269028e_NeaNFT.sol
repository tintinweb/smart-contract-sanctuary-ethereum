// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 *
 *                                    (/  #%%                                    
 *                                 ((((   %%%%%*                                 
 *                                /(/(,  #%%%%%%*                                
 *                          (((((/((/(   %%%%%%%%#%%%%/                          
 *                       ((((((((((((/  *%%%%%%%%%%%%%%%%#                       
 *                      /((((((((((((*  #%%%%%%%%%%%%%%%%%%%                     
 *                        ./(((((((((,  #%%%%%%%%%%%%%%%%%%%%%                   
 *                 *(((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%                  
 *                ,((((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%                 
 *                (((((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%%                
 *               .(/(((((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%#.               
 *                    (((((((((((((((   %%%%%%%%%%%%%%%%%%%%%%%%%                
 *                   /(((((((((((((((   %%%%%%%%%%%%%%%%%%%%%##*                 
 *               *(((((((((((((((((((   %%%%%#%%#%%%%%%%%%%#%%                   
 *                (((((((((((((((((((.  %%%%%          %%%%%%                    
 *                (((((((((((((((((((,  #%%%         .%%%%%%,                    
 *                 ((((((((((((((((((/  (%%%       %%%%%%%%%.                    
 *                           ((((((((/  ,%%%   .%%%%%%%%%%%%%                    
 *                        *((((((((((/   %%#   %%%%%%%%%%%%%%                    
 *                    //((((((((((((((        ,%%%%%%%%%%%%%.                    
 *                      ((((((((((((((        %%%%%%%%%%%%(                      
 *                        (//(((((((((       *%%%%%%%%%#%                        
 *                          /(((((((((,      %%%%%%#%%(                          
 *                             (((((((*     *%%%%%%%                             
 *                               ./((((     %%%%#  
 * 
 * Hello Guardians,
 * We don't have a lot of time. You have been called upon to act, the time is now or never.
 * Together we can collectively push back the damage that has been done to the amazon.
 * 
 * This contract stands to emit a digitally owned slice of property which you can use 
 * to join the fight. Gas saving measures have been used to even further reduce carbon emission.
 * ~ See you in the rainforest.
 *
 * Project By: @nemus_earth
 * Developed By: @notmokk
 *
 *
 * Error Legend
 * ---------------------------------------
 * E01: Not on allow list
 * E02: Cannot mint 0 NFTs
 * E03: Not enough tickets for redemption
 * E04: Not authenticated for call
 * E05: Address cannot be 0
 * E06: Timestamp cannot be in the past
 * E07: Token Mode must be 0 to transfer
 * E08: Token cannot already be in mode
 * E09: Non matching lengths
 * E10: Mode setting not allowed
 * 
 */

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

interface MintTicketFactory {
    function getTicketSizeID(uint256 id) external returns(uint8);
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface ConservationInterface {
    function conserve(uint256 tokenId) external;
    function remove(uint256 tokenId) external;
}

interface ExplorationInterface {
    function explore(uint256 tokenId) external;
    function remove(uint256 tokenId) external;
}

contract NeaNFT is Ownable, ERC721A, ReentrancyGuard
{
    uint32 public earlyAccessEnds;

    uint8 constant NO_MODE = 0;
    uint8 constant EXPLORATION_MODE = 1;
    uint8 constant CONSERVATION_MODE = 2;
    uint8 constant COMBO_MODE = 3;

    bool public allowConservation = false;
    bool public allowExploration = false;
    bool public allowComboMode = false;
    bool public allowModeSetting = false;

    struct TokenData {
        uint8 tokenSize;
        uint8 tokenMode;
        string tokenTier;
    }

    struct RedeemParams {
        uint256[] mtIndexes; 
        uint256[] amounts;
        uint256[] _parcelId; 
        uint256[] _size;
        uint256[] _gridId;
    }

    mapping(uint256 => TokenData) tokenDataStorage;
    mapping(address => bool) public allowlist;

    MintTicketFactory public neaMintTicketFactory;
    ConservationInterface public conservationContract;
    ExplorationInterface public explorationContract;

    event Redeemed(address indexed account, uint256[] mtIndexes, uint256[] amounts, uint256[] _tokenIds, uint256[] _parcelId, uint256[] _size, uint256[] _gridId);

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        string memory name,
        string memory symbol,
        address _mintTicketAddress,
        uint32 _earlyAccessEnds
    ) ERC721A(name, symbol, maxBatchSize_, collectionSize_) {
        neaMintTicketFactory = MintTicketFactory(_mintTicketAddress);
        earlyAccessEnds = _earlyAccessEnds;
    }

    function redeem(
            RedeemParams calldata params
        ) public virtual {

        if (block.timestamp < earlyAccessEnds ) {
            require(allowlist[_msgSender()], 'E01');
        }

        uint256 totalSupply = totalSupply();
        uint256 amountToMint;

        //check to make sure all are valid then re-loop for redemption 
        for(uint i = 0; i < params.mtIndexes.length; i++) {
            require(params.amounts[i] > 0, 'E02');
            require(neaMintTicketFactory.balanceOf(_msgSender(), params.mtIndexes[i]) >= params.amounts[i], 'E03');
            amountToMint += params.amounts[i];
        }

        uint localSupply = 0;
        uint256[] memory tokenIdStorage = new uint256[](amountToMint);

        for(uint i = 0; i < params.mtIndexes.length; i++) {
            uint8 sizeID = neaMintTicketFactory.getTicketSizeID(params.mtIndexes[i]);
            neaMintTicketFactory.burnFromRedeem(_msgSender(), params.mtIndexes[i], params.amounts[i]);
            _safeMint(_msgSender(), params.amounts[i]);
            for(uint j = 0; j < params.amounts[i]; j++) {
                tokenDataStorage[totalSupply + localSupply].tokenMode = NO_MODE;
                tokenDataStorage[totalSupply + localSupply ].tokenSize = sizeID;
                tokenIdStorage[localSupply] = totalSupply + localSupply;
                localSupply++;
            }
        }
        emit Redeemed(_msgSender(), params.mtIndexes, params.amounts, tokenIdStorage, params._parcelId, params._size, params._gridId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function seedAllowlist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = true;
        }
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function getSizeId(uint256 tokenId) external view returns (uint256) {
        return tokenDataStorage[tokenId].tokenSize;
    }

    function getTokenMode(uint256 tokenId) external view returns (uint256) {
        return tokenDataStorage[tokenId].tokenMode;
    }

    function getTokenTier(uint256 tokenId) external view returns (string memory) {
        return tokenDataStorage[tokenId].tokenTier;
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTokenMode(uint256 tokenId, uint8 tokenMode) external nonReentrant {
        require(_msgSender() == owner() || _msgSender() == ownerOf(tokenId), 'E04');
        require(tokenDataStorage[tokenId].tokenMode != tokenMode, 'E08');
        require(allowModeSetting, 'E10');

        if ( tokenMode == CONSERVATION_MODE ) {
            require(allowConservation, "E10");
            conservationContract.conserve(tokenId);
        }

        if ( tokenMode == EXPLORATION_MODE ) {
            require(allowExploration, "E10");
            explorationContract.explore(tokenId);
        }

        if ( tokenMode == COMBO_MODE ) {
            require(allowComboMode, "E10");
            explorationContract.explore(tokenId);
            conservationContract.conserve(tokenId);
        }

        tokenDataStorage[tokenId].tokenMode = tokenMode;
    }

    function resetTokenMode(uint256 tokenId) external nonReentrant {

        uint8 currentTokenMode = tokenDataStorage[tokenId].tokenMode;

        require(_msgSender() == owner() || _msgSender() == ownerOf(tokenId), 'E04');
        require(currentTokenMode != NO_MODE, 'E08');
        require(allowModeSetting, 'E10');

        if ( currentTokenMode == EXPLORATION_MODE ) {
            explorationContract.remove(tokenId);
        }

        if ( currentTokenMode == CONSERVATION_MODE ) {
            conservationContract.remove(tokenId);
        }

        if ( currentTokenMode == COMBO_MODE ) {
            explorationContract.remove(tokenId);
            conservationContract.remove(tokenId);
        }

        tokenDataStorage[tokenId].tokenMode = NO_MODE;

    }

    function setMintTicketAddress(address _mintTicketAddress) external onlyOwner {
        require(address(_mintTicketAddress) != address(0), 'E05');
        neaMintTicketFactory = MintTicketFactory(_mintTicketAddress);
    }

    function setExplorationAddress(address _explorationAddress) external onlyOwner {
        require(address(_explorationAddress) != address(0), 'E05');
        explorationContract = ExplorationInterface(_explorationAddress);
    }

    function setConservationAddress(address _conservationAddress) external onlyOwner {
        require(address(_conservationAddress) != address(0), 'E05');
        conservationContract = ConservationInterface(_conservationAddress);
    }

    function setEarlyAccessEnds(uint32 _earlyAccessEnds) external onlyOwner {
        require(_earlyAccessEnds > block.timestamp, "E06");
        earlyAccessEnds = _earlyAccessEnds;
    }

    function setAllowTokenMode(bool _allowModeSetting) external onlyOwner {
        allowModeSetting = _allowModeSetting;
    }

    function setAllowConservation(bool _allowConservation) external onlyOwner {
        allowConservation = _allowConservation;
    }


    function setAllowExploration(bool _allowExploration) external onlyOwner {
        allowExploration = _allowExploration;
    }


    function setAllowComboMode(bool _allowComboMode) external onlyOwner {
        allowComboMode = _allowComboMode;
    }

    function batchSetTokenTier(uint256[] calldata _tokenIds, string[] calldata _tokenTiers) external onlyOwner {
        require(_tokenIds.length == _tokenTiers.length, 'E09');
         for (uint256 i = 0; i < _tokenIds.length; i++) {
             tokenDataStorage[_tokenIds[i]].tokenTier = _tokenTiers[i];
         }
    }

    function _beforeTokenTransfers( address _from, address _to, uint256 _startTokenId, uint256 _quantity) internal virtual override {
        require(tokenDataStorage[_startTokenId].tokenMode == NO_MODE, "E07");
        super._beforeTokenTransfers(_from, _to, _startTokenId, _quantity);
    }

}