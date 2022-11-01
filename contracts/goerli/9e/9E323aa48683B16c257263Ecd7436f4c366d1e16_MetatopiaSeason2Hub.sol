// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/ITopia.sol";
import "../interfaces/IGenesis.sol";

// all in one contract for receiving staked NFTs and distributing daily topia payouts

contract MetatopiaSeason2Hub is Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    IGenesis public GenesisInterface;
    ITopia public TopiaInterface;
    IERC721 public Genesis = IERC721(0x97A792aCE504c2590C5046A7768A91CAd8aa0971); // Genesis NFT contract
    IERC721 public Alpha = IERC721(0xdf4F2DA93C07d590E16D34d2c19d3Ba93CB13E98);
    IERC721 public Wastelands = IERC721(0xB710a21680dCB32f6D4661Bcc015de8c13767559);

    // 1=runner, 2=bull, 3=matador
    // 4=cadet, 5=alien, 6=general, 
    // 7=baker, 8=foodie, 9=shopowner, 
    // 10=cat, 11=dog, 12=vet
    mapping(uint16 => uint8) public genesisIdentifier; 
    mapping(address => bool) gameContracts;

    // ******* PLATOONS / LITTERS / MOBS / UNIONS *********

    mapping(address => EnumerableSet.UintSet) Platoons;
    mapping(address => EnumerableSet.UintSet) Litters;
    mapping(address => EnumerableSet.UintSet) Mobs;
    mapping(address => EnumerableSet.UintSet) Unions;

    // ******* BULLRUN *******
    uint16 private numRunnersStaked;
    uint16 private numBullsStaked;
    EnumerableSet.UintSet private matadorIds; // staked matador nft ids
    mapping(uint16 => address) private OriginalMatadorOwner; 
    mapping(uint16 => address) private OriginalBullOwner;
    mapping(uint16 => address) private OriginalRunnerOwner;

    // ************ MOONFORCE ************
    uint16 private numCadetsStaked; // staked cadet nft ids
    EnumerableSet.UintSet private alienIds; // ..
    uint16 private numGeneralsStaked;
    mapping(uint16 => address) private OriginalCadetOwner; 
    mapping(uint16 => address) private OriginalAlienOwner; 
    mapping(uint16 => address) private OriginalGeneralOwner;

    // ************ DOGEWORLD ************
    uint16 private numCatsStaked;
    uint16 private numDogsStaked;
    EnumerableSet.UintSet private vetIds;
    mapping(uint16 => address) private OriginalCatOwner; 
    mapping(uint16 => address) private OriginalDogOwner; 
    mapping(uint16 => address) private OriginalVetOwner;

    // ************ PYE MARKET ************
    uint16 private numBakersStaked; // staked baker nft ids
    uint16 private numFoodiesStaked; // ..
    EnumerableSet.UintSet private shopOwnerIds;
    mapping(uint16 => address) private OriginalBakerOwner; 
    mapping(uint16 => address) private OriginalFoodieOwner; 
    mapping(uint16 => address) private OriginalShopOwnerOwner;

    // ------------------------------------
    // mapping for alpha token id to wallet of staker
    mapping(uint16 => address) private OriginalAlphaOwner;
    // mapping for rat token id to wallet of staker
    mapping(uint16 => address) private OriginalRatOwner;
    // all rat ids staked
    EnumerableSet.UintSet private ratIds;
    // all alpha ids staked
    EnumerableSet.UintSet private alphaIds;
    // all wasteland token ids staked
    EnumerableSet.UintSet private wastelandIds;
    // array of owned wasteland ids
    mapping(address => EnumerableSet.UintSet) wastelandOwnedIds;
    // array of Owned Genesis token ids
    mapping(address => mapping(uint8 => EnumerableSet.UintSet)) genesisOwnedIds;
    // array of Owned Alpha token ids
    mapping(address => mapping(uint8 => EnumerableSet.UintSet)) alphaOwnedIds;
    // array of Owned Rat token ids
    mapping(address => EnumerableSet.UintSet) ratOwnedIds;
    // number of Genesis staked
    uint256 public numGenesisStaked;
    // number of Alpha staked
    uint256 public numAlphasStaked;
    // number of rats staked;
    uint256 public numRatsStaked;

    // amount of $TOPIA earned so far per holder
    mapping(address => uint256) public totalHolderTOPIA;
    // mapping for alpha tokenId to game it's being staked in
    mapping(uint16 => uint8) public alphaGameIdentifier;
    // mapping for rat tokenId to game it's being staked in
    mapping(uint16 => uint8) public ratGameIdentifier;
    // mapping for genesis tokenId to game it's being staked in
    mapping(uint16 => uint8) genesisGameIdentifier;
    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    constructor(address _topia) {
        TopiaInterface = ITopia(_topia);
    }

    // ************* EVENTS

    event TopiaClaimed (address indexed owner, uint256 earned, uint256 blockNum, uint256 timeStamp);
    event AlphaReceived (address indexed _originalOwner, uint16 _id);
    event AlphaReturned (address indexed _originalOwner, uint16 _id);
    event RatReceived (address indexed _originalOwner, uint16 _id);
    event RatReturned (address indexed _originalOwner, uint16 _id);
    event BullReceived (address indexed _originalOwner, uint16 _id);
    event BullReturned (address indexed _returnee, uint16 _id);
    event MatadorReceived (address indexed _originalOwner, uint16 _id);
    event MatadorReturned (address indexed _returnee, uint16 _id);
    event RunnerReceived (address indexed _originalOwner, uint16 _id);
    event RunnerReturned (address indexed _returnee, uint16 _id);
    event CadetReceived (address indexed _originalOwner, uint16 _id);
    event CadetReturned (address indexed _returnee, uint16 _id);
    event AlienReceived (address indexed _originalOwner, uint16 _id);
    event AlienReturned (address indexed _returnee, uint16 _id);
    event GeneralReceived (address indexed _originalOwner, uint16 _id);
    event GeneralReturned (address indexed _returnee, uint16 _id);
    event CatReceived (address indexed _originalOwner, uint16 _id);
    event CatReturned (address indexed _returnee, uint16 _id);
    event DogReceived (address indexed _originalOwner, uint16 _id);
    event DogReturned (address indexed _returnee, uint16 _id);
    event VetReceived (address indexed _originalOwner, uint16 _id);
    event VetReturned (address indexed _returnee, uint16 _id);
    event BakerReceived (address indexed _originalOwner, uint16 _id);
    event BakerReturned (address indexed _returnee, uint16 _id);
    event FoodieReceived (address indexed _originalOwner, uint16 _id);
    event FoodieReturned (address indexed _returnee, uint16 _id);
    event ShopOwnerReceived (address indexed _originalOwner, uint16 _id);
    event ShopOwnerReturned (address indexed _returnee, uint16 _id);
    event NFTStolen (address indexed _thief, address indexed _victim, uint16 _id);
    event PlatoonCreated (address indexed _creator, uint16[] cadets);
    event LitterCreated (address indexed _creator, uint16[] cats);
    event MobCreated (address indexed _creator, uint16[] runners);
    event UnionCreated (address indexed _creator, uint16[] bakers);
    event CadetAdded (address indexed _owner, uint16 _id);
    event CatAdded (address indexed _owner, uint16 _id);
    event RunnerAdded (address indexed _owner, uint16 _id);
    event BakerAdded (address indexed _owner, uint16 _id);
    event GroupUnstaked (address indexed _unstaker);
    event MatadorMigrated (address indexed _owner, uint16 _id);
    event GeneralMigrated (address indexed _owner, uint16 _id);
    event ShopOwnerMigrated (address indexed _owner, uint16 _id);
    event VetMigrated (address indexed _owner, uint16 _id);
    
    // ************* Universal TOPIA functions

    function pay(address _to, uint256 _amount) external onlyGames() {
        TopiaInterface.mint(_to, _amount);
        totalHolderTOPIA[_to] += _amount;
        totalTOPIAEarned += _amount;
        emit TopiaClaimed(_to, _amount, block.number, block.timestamp);
    }

    function burnFrom(address _to, uint256 _amount) external onlyGames() {
        TopiaInterface.burnFrom(_to, _amount);
    }

    // ************* MODIFIERS

    modifier onlyGames() {
        require(gameContracts[msg.sender], "only game contract allowed");
        _;
    }

    // ************* SETTERS

    function setGenesis(address _genesis) external onlyOwner {
        Genesis = IERC721(_genesis);
        GenesisInterface = IGenesis(_genesis);
    }

    function setTopia(address _topia) external onlyOwner {
        TopiaInterface = ITopia(_topia);
    }

    // mass update the genesisIdentifier mapping
    function batchSetGenesisIdentifier(uint16[] calldata _idNumbers, uint8[] calldata _types) external onlyOwner {
        require(_idNumbers.length == _types.length);
        for (uint16 i = 0; i < _idNumbers.length;) {
            require(_types[i] != 0 && _types[i] <= 12);
            genesisIdentifier[_idNumbers[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    // ************* EVENT FXNS

    function balanceOf(address owner) external view returns (uint256) {
        uint256 gen;
        for(uint8 i = 1; i <= 5; i++) {
            gen += genesisOwnedIds[owner][i].length();
        }
        
        gen += Mobs[owner].length();
        gen += Platoons[owner].length();
        gen += Litters[owner].length();
        gen += Unions[owner].length();

        uint256 alph;
        for(uint8 i = 1; i <= 5; i++) {
            alph += alphaOwnedIds[owner][i].length();
        }

        uint256 stakedBalance = alph + wastelandOwnedIds[owner].length() + gen;
        return stakedBalance;
    }

    function getUserGenesisStaked(address owner) external view returns (uint16[] memory stakedGenesis) {
        uint256 length;
        for(uint8 i = 1; i <= 5; i++) {
            length += genesisOwnedIds[owner][i].length();
        }

        length += Mobs[owner].length();
        length += Platoons[owner].length();
        length += Litters[owner].length();
        length += Unions[owner].length();

        stakedGenesis = new uint16[](length);
        uint y = 0;
        for(uint8 i = 1; i <= 5; i++) {
            uint256 L = genesisOwnedIds[owner][i].length();
            for(uint z = 0; z < L; z++) {
                stakedGenesis[y] = uint16(genesisOwnedIds[owner][i].at(z));
                y++;
            }
        }
        for(uint i = 0; i < Mobs[owner].length(); i++) {
            stakedGenesis[y] = uint16(Mobs[owner].at(i));
            y++;
        }
        for(uint i = 0; i < Platoons[owner].length(); i++) {
            stakedGenesis[y] = uint16(Platoons[owner].at(i));
            y++;
        }
        for(uint i = 0; i < Litters[owner].length(); i++) {
            stakedGenesis[y] = uint16(Litters[owner].at(i));
            y++;
        }
        for(uint i = 0; i < Unions[owner].length(); i++) {
            stakedGenesis[y] = uint16(Unions[owner].at(i));
            y++;
        }
    }

    function getUserStakedGenesisGame(address owner, uint8 game) external view returns (uint16[] memory stakedGenesis) {
        uint256 length = genesisOwnedIds[owner][game].length();
        stakedGenesis = new uint16[](length);

        for(uint i = 0; i < length;) {
            stakedGenesis[i] = uint16(genesisOwnedIds[owner][game].at(i));
            unchecked{ i++; }
        }
    }

    function getUserAlphaStaked(address owner) external view returns (uint16[] memory stakedAlphas) {
        uint256 length;
        for(uint8 i = 1; i <= 5; i++) {
            length += alphaOwnedIds[owner][i].length();
        }

        stakedAlphas = new uint16[](length);
        uint y = 0;
        for(uint8 i = 1; i <= 5; i++) {
            uint256 L = alphaOwnedIds[owner][i].length();
            for(uint z = 0; z < L; z++) {
                stakedAlphas[y] = uint16(alphaOwnedIds[owner][i].at(z));
                y++;
            }
        }
    }

    function getUserStakedAlphaGame(address owner, uint8 game) external view returns (uint16[] memory stakedAlphas) {
        uint256 length = alphaOwnedIds[owner][game].length();
        stakedAlphas = new uint16[](length);

        for(uint i = 0; i < length;) {
            stakedAlphas[i] = uint16(alphaOwnedIds[owner][game].at(i));
            unchecked{ i++; }
        }
    }

    function getUserRatStaked(address owner) external view returns (uint16[] memory stakedRats) {
        uint256 length = ratOwnedIds[owner].length();
        stakedRats = new uint16[](length);

        for(uint i = 0; i < length;) {
            stakedRats[i] = uint16(ratOwnedIds[owner].at(i));
            unchecked{ i++; }
        }
    }

    // ************ ALPHA NFT RECEIVE AND RETURN FUNCTIONS

    // @param: _gameIdentifier 1 = BullRun, 2 = MoonForce, 3 = Doge World, 4 = PYE Market, 5 = Wastelands
    function receiveAlpha(address _originalOwner, uint16 _id, uint8 _gameIdentifier) external onlyGames {
        require(_gameIdentifier >= 1 && _gameIdentifier <= 5 , "invalid id");
        IERC721(Alpha).safeTransferFrom(_originalOwner, address(this), _id);
        OriginalAlphaOwner[_id] = _originalOwner;
        alphaIds.add(_id);
        alphaGameIdentifier[_id] = _gameIdentifier;
        alphaOwnedIds[_originalOwner][_gameIdentifier].add(_id);
        numAlphasStaked++;
        emit AlphaReceived(_originalOwner, _id);
    }

    function returnAlphaToOwner(address _returnee, uint16 _id, uint8 _gameIdentifier) external onlyGames {
        require(_returnee == OriginalAlphaOwner[_id], "not owner");
        IERC721(Alpha).safeTransferFrom(address(this), _returnee, _id);
        delete OriginalAlphaOwner[_id];
        delete alphaGameIdentifier[_id];
        alphaIds.remove(_id);
        alphaOwnedIds[_returnee][_gameIdentifier].remove(_id);
        numAlphasStaked--;

        emit AlphaReturned(_returnee, _id);
    }

    // ************ WASTELANDS NFT RECEIVE AND RETURN FUNCTIONS

    function receiveRat(address _originalOwner, uint16 _id, uint8 _gameIdentifier) external onlyGames {
        require(_gameIdentifier >= 1 && _gameIdentifier <= 5 , "invalid id");
        IERC721(Wastelands).safeTransferFrom(_originalOwner, address(this), _id);
        OriginalRatOwner[_id] = _originalOwner;
        ratIds.add(_id);
        ratGameIdentifier[_id] = _gameIdentifier;
        ratOwnedIds[_originalOwner].add(_id);
        numRatsStaked++;
        emit RatReceived(_originalOwner, _id);
    }

    function returnRatToOwner(address _returnee, uint16 _id) external onlyGames {
        require(_returnee == OriginalRatOwner[_id], "not owner");
        IERC721(Wastelands).safeTransferFrom(address(this), _returnee, _id);
        delete OriginalRatOwner[_id];
        delete ratGameIdentifier[_id];
        ratIds.remove(_id);
        ratOwnedIds[_returnee].remove(_id);
        numRatsStaked--;
        emit RatReturned(_returnee, _id);
    }

    // ************ METATOPIA WASTELANDS FUNCTIONS

    // for tier 3 NFTS being sent to wastelands 
    // @param: _gameId: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM
    // @param: returningFromWastelands, if the NFT has already been in the wastelands and user is trying to get it back
    function migrate(uint16 _id, address _originalOwner, uint8 _gameId, bool returningFromWastelands) external onlyGames {
        require(_gameId >= 1 && _gameId <= 4, "Invalid game id");
        if (_gameId == 1) { // incoming matador
            if (!returningFromWastelands) { // nft is being sent to the wastes
                Genesis.safeTransferFrom(_originalOwner, address(this), _id);
                genesisGameIdentifier[_id] = 5; // NFT goes to Wastelands
                OriginalMatadorOwner[_id] = _originalOwner;
                wastelandOwnedIds[_originalOwner].add(_id);
                wastelandIds.add(_id);
                emit MatadorMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                Genesis.safeTransferFrom(address(this), _originalOwner, _id);
                delete OriginalMatadorOwner[_id];
                delete genesisGameIdentifier[_id];
                wastelandIds.remove(_id);
                emit MatadorReturned(_originalOwner, _id);
            }
        } else if (_gameId == 2) { // incoming general
            if (!returningFromWastelands) { // nft is being sent to the wastes
                Genesis.safeTransferFrom(_originalOwner, address(this), _id);
                genesisGameIdentifier[_id] = 5; // NFT goes to Wastelands
                OriginalGeneralOwner[_id] = _originalOwner;
                wastelandOwnedIds[_originalOwner].add(_id);
                wastelandIds.add(_id);
                emit GeneralMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                Genesis.safeTransferFrom(address(this), _originalOwner, _id);
                delete OriginalGeneralOwner[_id];
                delete genesisGameIdentifier[_id];
                wastelandIds.remove(_id);
                emit GeneralReturned(_originalOwner, _id);
            }
        } else if (_gameId == 3) { // incoming vet
            if (!returningFromWastelands) { // nft is being sent to the wastes
                Genesis.safeTransferFrom(_originalOwner, address(this), _id);
                genesisGameIdentifier[_id] = 5; // NFT goes to Wastelands
                OriginalVetOwner[_id] = _originalOwner;
                wastelandOwnedIds[_originalOwner].add(_id);
                wastelandIds.add(_id);
                emit VetMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                Genesis.safeTransferFrom(address(this), _originalOwner, _id);
                delete OriginalVetOwner[_id];
                delete genesisGameIdentifier[_id];
                wastelandIds.remove(_id);
                emit VetReturned(_originalOwner, _id);
            }
        } else if (_gameId == 4) { // incoming shopowner
            if (!returningFromWastelands) { // nft is being sent to the wastes
                Genesis.safeTransferFrom(_originalOwner, address(this), _id);
                genesisGameIdentifier[_id] = 5; // NFT goes to Wastelands
                OriginalShopOwnerOwner[_id] = _originalOwner;
                wastelandOwnedIds[_originalOwner].add(_id);
                wastelandIds.add(_id);
                emit ShopOwnerMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                Genesis.safeTransferFrom(address(this), _originalOwner, _id);
                delete OriginalShopOwnerOwner[_id];
                delete genesisGameIdentifier[_id];
                wastelandIds.remove(_id);
                emit ShopOwnerReturned(_originalOwner, _id);
            }
        }
    }

    // ************ METATOPIA GENESIS NFT RECEIVE AND RETURN FUNCTIONS
    // @param: _gameId: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM, 5 = Wastelands
    // 1=runner, 2=bull, 3=matador
    // 4=cadet, 5=alien, 6=general, 
    // 7=baker, 8=foodie, 9=shopowner, 
    // 10=cat, 11=dog, 12=vet

    function receieveManyGenesis(address _originalOwner, uint16[] memory _ids, uint8[] memory identifiers, uint8 _gameIdentifier) external onlyGames {
        for(uint i = 0; i < _ids.length;) {
            if (identifiers[i] == 1) {                
                OriginalRunnerOwner[_ids[i]] = _originalOwner;
                numRunnersStaked++;                
                emit RunnerReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 2) {                
                OriginalBullOwner[_ids[i]] = _originalOwner;
                numBullsStaked++;                
                emit BullReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 3) {                
                OriginalMatadorOwner[_ids[i]] = _originalOwner;
                matadorIds.add(_ids[i]);                
                emit MatadorReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 4) {                
                OriginalCadetOwner[_ids[i]] = _originalOwner;
                numCadetsStaked++;                
                emit CadetReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 5) {                
                OriginalAlienOwner[_ids[i]] = _originalOwner;
                alienIds.add(_ids[i]);                
                emit AlienReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 6) {                
                OriginalGeneralOwner[_ids[i]] = _originalOwner;
                numGeneralsStaked++;                
                emit GeneralReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 7) {                
                OriginalBakerOwner[_ids[i]] = _originalOwner;
                numBakersStaked++;                
                emit BakerReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 8) {                
                OriginalFoodieOwner[_ids[i]] = _originalOwner;
                numFoodiesStaked++;        
                emit FoodieReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 9) {     
                OriginalShopOwnerOwner[_ids[i]] = _originalOwner;
                shopOwnerIds.add(_ids[i]);   
                emit ShopOwnerReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 10) {
                OriginalCatOwner[_ids[i]] = _originalOwner;
                numCatsStaked++;
                emit CatReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 11) {
                OriginalDogOwner[_ids[i]] = _originalOwner;
                numDogsStaked++;
                emit DogReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 12) {
                OriginalVetOwner[_ids[i]] = _originalOwner;
                vetIds.add(_ids[i]);
                emit VetReceived(_originalOwner, _ids[i]);
            }

            genesisGameIdentifier[_ids[i]] = _gameIdentifier;
            if (genesisIdentifier[_ids[i]] == 0) {
                genesisIdentifier[_ids[i]] = identifiers[i];
            }

            genesisOwnedIds[_originalOwner][_gameIdentifier].add(_ids[i]);
            Genesis.safeTransferFrom(_originalOwner, address(this), _ids[i]);

            unchecked{ i++; }
        }
        numGenesisStaked += _ids.length;
    }

    function returnGenesisToOwner(address _returnee, uint16 _id, uint8 identifier, uint8 _gameIdentifier) external onlyGames {
        if (identifier == 1) {
            require(_returnee == OriginalRunnerOwner[_id], "not owner");
            delete OriginalRunnerOwner[_id];
            delete genesisGameIdentifier[_id];
            numRunnersStaked--; 
            emit RunnerReturned(_returnee, _id);
        } else if (identifier == 2) {
            require(_returnee == OriginalBullOwner[_id], "not owner");
            delete OriginalBullOwner[_id];
            delete genesisGameIdentifier[_id];
            numBullsStaked--;
            emit BullReturned(_returnee, _id);
        } else if (identifier == 3) {
            require(_returnee == OriginalMatadorOwner[_id], "not owner");
            delete OriginalMatadorOwner[_id];
            delete genesisGameIdentifier[_id];
            matadorIds.remove(_id);
            emit MatadorReturned(_returnee, _id);
        } else if (identifier == 4) {
            require(_returnee == OriginalCadetOwner[_id], "not owner");
            delete OriginalCadetOwner[_id];
            delete genesisGameIdentifier[_id];
            numCadetsStaked--;
            emit CadetReturned(_returnee, _id);
        } else if (identifier == 5) {
            require(_returnee == OriginalAlienOwner[_id], "not owner");
            delete OriginalAlienOwner[_id];
            delete genesisGameIdentifier[_id];
            alienIds.remove(_id);
            emit AlienReturned(_returnee, _id);
        } else if (identifier == 6) {
            require(_returnee == OriginalGeneralOwner[_id], "not owner");
            delete OriginalGeneralOwner[_id];
            delete genesisGameIdentifier[_id];
            numGeneralsStaked--;
            emit GeneralReturned(_returnee, _id);
        } else if (identifier == 7) {
            require(_returnee == OriginalBakerOwner[_id], "not owner");
            delete OriginalBakerOwner[_id];
            delete genesisGameIdentifier[_id];
            numBakersStaked--;
            emit BakerReturned(_returnee, _id);
        } else if (identifier == 8) {
            require(_returnee == OriginalFoodieOwner[_id], "not owner");
            delete OriginalFoodieOwner[_id];
            delete genesisGameIdentifier[_id];
            numFoodiesStaked--;
            emit FoodieReturned(_returnee, _id);
        } else if (identifier == 9) {
            require(_returnee == OriginalShopOwnerOwner[_id], "not owner");
            delete OriginalShopOwnerOwner[_id];
            delete genesisGameIdentifier[_id];
            shopOwnerIds.remove(_id);
            emit ShopOwnerReturned(_returnee, _id);
        } else if (identifier == 10) {
            require(_returnee == OriginalCatOwner[_id], "not owner");
            delete OriginalCatOwner[_id];
            delete genesisGameIdentifier[_id];
            numCatsStaked--;
            emit CatReturned(_returnee, _id);
        } else if (identifier == 11) {
            require(_returnee == OriginalDogOwner[_id], "not owner");
            delete OriginalDogOwner[_id];
            delete genesisGameIdentifier[_id];
            numDogsStaked--;
            emit DogReturned(_returnee, _id);
        } else if (identifier == 12) {
            require(_returnee == OriginalVetOwner[_id], "not owner");
            delete OriginalVetOwner[_id];
            delete genesisGameIdentifier[_id];
            vetIds.remove(_id);
            emit VetReturned(_returnee, _id);
        }
        genesisOwnedIds[_returnee][_gameIdentifier].remove(_id);
        numGenesisStaked--;

        IERC721(Genesis).safeTransferFrom(address(this), _returnee, _id);
    }

    // ************** STEALING LOGIC ***************
    // @param: _gameId: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM, 5 = Wastelands
    // @param _id: the actual NFT id
    // @param: identifier:
    // 1=runner, 2=bull, 3=matador
    // 4=cadet, 5=alien, 6=general, 
    // 7=baker, 8=foodie, 9=shopowner, 
    // 10=cat, 11=dog, 12=vet
    function stealGenesis(uint16 _id, uint256 seed, uint8 _gameId, uint8 identifier, address _victim) external onlyGames returns (address thief) {
        uint256 bucket = (seed & 0xFFFFFFFF);
        if (_gameId == 1) { // is a bullrun nft
            if (identifier == 1) { // is a runner
                thief = OriginalAlphaOwner[uint16(alphaIds.at(bucket % alphaIds.length()))];
                delete OriginalRunnerOwner[_id];
            } else if (identifier == 2) { // is a bull
                thief = OriginalMatadorOwner[uint16(matadorIds.at(bucket % matadorIds.length()))];
                delete OriginalBullOwner[_id];
            }
        } else if (_gameId == 2) { // is a mf nft, aliens can't be stolen
            if (identifier == 4) { // is a cadet
                thief = OriginalAlienOwner[uint16(alienIds.at(bucket % alienIds.length()))];
                delete OriginalCadetOwner[_id];
            }
        } else if (_gameId == 3) { // is a dw nft
            if (identifier == 10) { // is a cat
                thief = OriginalAlphaOwner[uint16(alphaIds.at(bucket % alphaIds.length()))];
                delete OriginalCatOwner[_id];
            } else if (identifier == 11) { // is a dog
                thief = OriginalVetOwner[uint16(vetIds.at(bucket % vetIds.length()))];
                delete OriginalDogOwner[_id];               
            }
        } else if (_gameId == 4) { // is a pm nft
            if (identifier == 7) { // is a baker
                thief = OriginalAlphaOwner[uint16(alphaIds.at(bucket % alphaIds.length()))];
                delete OriginalBakerOwner[_id];
            } else if (identifier == 8) { // is a foodie
                thief = OriginalShopOwnerOwner[uint16(shopOwnerIds.at(bucket % shopOwnerIds.length()))];
                delete OriginalFoodieOwner[_id];
            }
        }
        IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
        emit NFTStolen(thief, _victim, _id);
    }

    // only tier 3 nfts can be stolen during wastelands migration
    // for tier 3's being SENT to wastes
    
    function stealMigratingGenesis(uint16 _id, uint256 seed, uint8 _gameId, address _victim, bool returningFromWastelands) external onlyGames returns (address thief) {
        uint256 bucket = (seed & 0xFFFFFFFF);
        if (_gameId == 1) { // steal matador
            thief = OriginalAlienOwner[uint16(alienIds.at(bucket % alienIds.length()))];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalMatadorOwner[_id];
        } else if (_gameId == 2) { // steal general
            thief = OriginalAlienOwner[uint16(alienIds.at(bucket % alienIds.length()))];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalGeneralOwner[_id];
        } else if (_gameId == 3) { // steal vet
            thief = OriginalAlienOwner[uint16(alienIds.at(bucket % alienIds.length()))];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalVetOwner[_id];
        } else if (_gameId == 4) { // steal shopowner
            thief = OriginalAlienOwner[uint16(alienIds.at(bucket % alienIds.length()))];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalShopOwnerOwner[_id];
        }
        emit NFTStolen(thief, _victim, _id);
    }

    // ************ UNIVERSAL NFT GROUPING FXNS (PLATOONS, MOBS, LITTERS, UNIONS) *************

    // @param: _ids: NFT ids being staked together to form a platoon, litter... etc
    // @param: _creator: address of the person creating their group (staker)
    // @param: _gameIdentifier: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM

    function createGroup(uint16[] calldata _ids, address _creator, uint8 _gameIdentifier) external onlyGames {
        uint16 length = uint16(_ids.length); 
        for (uint i = 0; i < length;) {
            uint8 identifier;
            if (_gameIdentifier == 1) { // must be mob
                    Genesis.safeTransferFrom(_creator, address(this), _ids[i]);
                    Mobs[_creator].add(_ids[i]);

                    OriginalRunnerOwner[_ids[i]] = _creator;
                    numRunnersStaked++;
                    identifier = 1;
                    emit RunnerReceived(_creator, _ids[i]);
            } else if (_gameIdentifier == 2) { // must be platoon
                    Genesis.safeTransferFrom(_creator, address(this), _ids[i]);
                    Platoons[_creator].add(_ids[i]);

                    OriginalCadetOwner[_ids[i]] = _creator;
                    numCadetsStaked++;
                    identifier = 4;
                    emit CadetReceived(_creator, _ids[i]);
            } else if (_gameIdentifier == 3) { // must be litter
                    Genesis.safeTransferFrom(_creator, address(this), _ids[i]);
                    Litters[_creator].add(_ids[i]);

                    OriginalCatOwner[_ids[i]] = _creator;
                    numCatsStaked++;
                    identifier = 10;
                    emit CatReceived(_creator, _ids[i]);
            } else if (_gameIdentifier == 4) { // must be union
                    IERC721(Genesis).safeTransferFrom(_creator, address(this), _ids[i]);
                    Unions[_creator].add(_ids[i]);

                    OriginalBakerOwner[_ids[i]] = _creator;
                    numBakersStaked++;
                    identifier = 7;
                    emit BakerReceived(_creator, _ids[i]);
            }
            genesisGameIdentifier[_ids[i]] = _gameIdentifier;
            if (genesisIdentifier[_ids[i]] == 0) {
                genesisIdentifier[_ids[i]] = identifier;
            }

            genesisOwnedIds[_creator][_gameIdentifier].add(_ids[i]);

            unchecked { i++; }
        }
        numGenesisStaked += length;

        if (_gameIdentifier == 1) { 
            emit MobCreated(_creator, _ids); 
        } else if (_gameIdentifier == 2) { 
            emit PlatoonCreated(_creator, _ids); 
        } else if (_gameIdentifier == 3) { 
            emit LitterCreated(_creator, _ids);
        } else if (_gameIdentifier == 4) { 
            emit UnionCreated(_creator, _ids);
        }
    }

    function addToGroup(uint16 _id, address _creator, uint8 _gameIdentifier) external onlyGames {

        if (_gameIdentifier == 1) { // must be mob
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                Mobs[_creator].add(_id);

                OriginalRunnerOwner[_id] = _creator;
                numRunnersStaked++;
                emit RunnerReceived(_creator, _id);
        } else if (_gameIdentifier == 2) { // must be platoon
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                Platoons[_creator].add(_id);

                OriginalCadetOwner[_id] = _creator;
                numCadetsStaked++;
                emit CadetReceived(_creator, _id);
        } else if (_gameIdentifier == 3) { // must be litter
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                Litters[_creator].add(_id);

                OriginalCatOwner[_id] = _creator;
                numCatsStaked++;
                emit CatReceived(_creator, _id);
        } else if (_gameIdentifier == 4) { // must be union
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                Unions[_creator].add(_id);

                OriginalBakerOwner[_id] = _creator;
                numBakersStaked++;
                emit BakerReceived(_creator, _id);
        }
        numGenesisStaked++;

        
        if (_gameIdentifier == 1) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 1;
            }
            emit RunnerAdded(_creator, _id); 
        } else if (_gameIdentifier == 2) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 4;
            }
            emit CadetAdded(_creator, _id); 
        } else if (_gameIdentifier == 3) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 10;
            }
            emit CatAdded(_creator, _id);
        } else if (_gameIdentifier == 4) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 7;
            }
            emit BakerAdded(_creator, _id);
        }

    }

    function unstakeGroup(address _creator, uint8 _gameIdentifier) external onlyGames {

        if (_gameIdentifier == 1) { // must be mob
                delete Mobs[_creator];
        } else if (_gameIdentifier == 2) { // must be platoon 
                delete Platoons[_creator];
        } else if (_gameIdentifier == 3) { // must be litter
                delete Litters[_creator];
        } else if (_gameIdentifier == 4) { // must be union
                delete Unions[_creator];
        }     
        emit GroupUnstaked(_creator);
    } 

    // ************ BULLRUN GAME FUNCTIONS

    function getBullOwner(uint16 _id) external view returns (address) {
        return OriginalBullOwner[_id];
    }

    function getMatadorOwner(uint16 _id) external view returns (address) {
        return OriginalMatadorOwner[_id];
    }

    function getRunnerOwner(uint16 _id) external view returns (address) {
        return OriginalRunnerOwner[_id];
    }

    function matadorCount() public view returns (uint16) {
        return uint16(matadorIds.length());
    }

    function bullCount() public view returns (uint16) {
        return numBullsStaked;
    }

    function runnerCount() public view returns (uint16) {
        return numRunnersStaked;
    }

    // ************ MOONFORCE GAME FUNCTIONS

    function getCadetOwner(uint16 _id) external view returns (address) {
        return OriginalCadetOwner[_id];
    }

    function getAlienOwner(uint16 _id) external view returns (address) {
        return OriginalAlienOwner[_id];
    }

    function getGeneralOwner(uint16 _id) external view returns (address) {
        return OriginalGeneralOwner[_id];
    }

    function cadetCount() external view returns (uint16) {
        return numCadetsStaked;
    }

    function alienCount() external view returns (uint16) {
        return uint16(alienIds.length());
    }

    function generalCount() external view returns (uint16) {
        return numGeneralsStaked;
    }

    // ************ DOGE WORLD GAME FUNCTIONS
    
    function getCatOwner(uint16 _id) external view returns (address) {
        return OriginalCatOwner[_id];
    }

    function getDogOwner(uint16 _id) external view returns (address) {
        return OriginalDogOwner[_id];
    }

    function getVetOwner(uint16 _id) external view returns (address) {
        return OriginalVetOwner[_id];
    }

    function catCount() external view returns (uint16) {
        // return uint16(catIds.length());
        return numCatsStaked;
    }

    function dogCount() external view returns (uint16) {
        // return uint16(dogIds.length());
        return numDogsStaked;
    }

    function vetCount() external view returns (uint16) {
        return uint16(vetIds.length());
    }

    // ************ PYE MARKET GAME FUNCTIONS
    
    function getBakerOwner(uint16 _id) external view returns (address) {
        return OriginalBakerOwner[_id];
    }

    function getFoodieOwner(uint16 _id) external view returns (address) {
        return OriginalFoodieOwner[_id];
    }

    function getShopOwnerOwner(uint16 _id) external view returns (address) {
        return OriginalShopOwnerOwner[_id];
    }

    function bakerCount() external view returns (uint16) {
        return numBakersStaked;
    }

    function foodieCount() external view returns (uint16) {
        return numFoodiesStaked;
    }

    function shopOwnerCount() external view returns (uint16) {
        return uint16(shopOwnerIds.length());
    }

    function setGameContract(address _contract, bool flag) external onlyOwner {
        gameContracts[_contract] = flag;
    }

    // ************ ALPHA AND RAT COUNT ***************

    function alphaCount() external view returns (uint16) {
        return uint16(alphaIds.length());
    }

    function ratCount() external view returns (uint16) {
        return uint16(ratIds.length());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IGenesis {

    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITopia {

    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;  
    function burnFrom(address _from, uint256 _amount) external;
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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