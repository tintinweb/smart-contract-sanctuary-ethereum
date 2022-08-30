// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IERC721TokenReceiver.sol";
import "./pioneers_trails/PioneersTrails.sol";



contract Pioneers is IERC721, IERC721Metadata{ 


    constructor(bytes32 _wagonRoot, address _access, address _trails){
        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        //        supportedInterfaces[0x780e9d63] = true; //ERC721Enumerable
        supportedInterfaces[0x01ffc9a7] = true; //ERC165

        owner = msg.sender;
        wagonRoot = _wagonRoot;
        access = _access;
        trails = _trails;
    }

    address public owner;
    address access;
    address trails;

    // ERRORS
    error PIONEERS_NoUpkeepNeeded();

    //GAME VARS
    uint constant MAX_WAGONS = 38611;       //from table

    uint constant MINT_COST = 60 ether;  //TODO:

    uint constant MINT_PERCENT_PRIZE       = 85; //TODO:
    uint constant MINT_PERCENT_LOOT       = 1; //TODO:
    uint constant MINT_PERCENT_CREATOR      = 14;

    uint constant SUPPLY_PERCENT_PRIZE  = 90;
    uint constant SUPPLY_PERCENT_CREATOR = 10;

    uint constant CHANGE_TRAIL_BASE_PRICE = 20 ether; //TODO:
    uint constant CHANGE_TRAIL_PERCENT_PRIZE  = 90;
    uint constant CHANGE_TRAIL_PERCENT_CREATOR = 10;

    uint public startTime;
    uint SALE_TIME = 10 seconds;
    // uint EARLY_ACCESS_TIME = 2 days;

    uint public boughtSupplies;
    uint public changedTrails;
    uint public destroyed;
    uint public settledFunds;


    //METADATA VARS
    string private __name = "Pioneers NFT (Season 1)";
    string private __symbol = "PIONEERS1";
    bytes private __uriBase;//
    bytes private __uriSuffix;//

    //////===721 Implementation
    mapping(address => uint256) internal balances;
    mapping (uint256 => address) internal allowance;
    mapping (address => mapping (address => bool)) internal authorised;


    uint16[] tokenIndexToWagon;
    mapping(uint16 => uint) public wagonToToken;
    mapping(uint16 => uint8[2]) items;
    mapping(uint16 => bytes1) wagonToFirstLetter;
    mapping(uint256 => address) owners;

    mapping(uint => bytes32) structuralData;
    mapping(uint => uint8) tokenToTrail; /** Associa un tokenId al percorso su cui viaggia. */
    mapping(address => uint) lastAmbushes; /** Associa un account al block.number nel momento dell'ultimo Ambush effettuato. */

    function getStructuralData(uint _tokenId) public view returns (uint8 supplies, uint8 ambushes, bytes32 lastAmbush){
        bytes32 _data = structuralData[_tokenId];

        supplies = uint8(uint(((_data << 248) >> 248)));
        ambushes = uint8(uint(((_data << 240) >> 240) >> 8));
        lastAmbush = (_data >> 16);

        return (supplies, ambushes, lastAmbush);
    }
    
    function setStructuralData(uint _tokenId, uint8 supplies, uint8 ambushes, bytes32 lastAmbush) internal{
        bytes32 _supplies = bytes32(uint(supplies));
        bytes32 _ambushes = bytes32(uint(ambushes)) << 8;
        bytes32 _lastAmbush = encodeAmbush(lastAmbush) << 16;

        structuralData[_tokenId] = _supplies ^ _ambushes ^ _lastAmbush;
    }

    function encodeAmbush(bytes32 _ambush) internal pure returns(bytes32){
        return (_ambush << 16) >> 16;
    }

    function tokenToWagon(uint _tokenId) public view returns(uint16){
        return tokenIndexToWagon[_tokenId - 1];
    }

    enum Stage {Initial, Minting, Journey1, Journey2, Journey3, Journey4, Destination}

    function startMinting() public{
        require(msg.sender == owner,"owner");

        require(startTime == 0,"started");
        startTime = block.timestamp;
    }

    function stage() public view returns(Stage){ // TODO;
        if(startTime == 0){
             return Stage.Initial;
        }else if(block.timestamp < startTime + SALE_TIME && tokenIndexToWagon.length < MAX_WAGONS){
             return Stage.Minting;
        }else if(totalSupply() > ((4*tokenIndexToWagon.length)/3) && totalSupply() <= tokenIndexToWagon.length){
             return Stage.Journey1;
        }else if(totalSupply() > tokenIndexToWagon.length/2 && totalSupply() <= ((4*tokenIndexToWagon.length)/3)){
             return Stage.Journey2;
        }else if(totalSupply() > tokenIndexToWagon.length/4 && totalSupply() <= tokenIndexToWagon.length/2){
             return Stage.Journey3;
        }else if(totalSupply() > 1 && totalSupply() <= tokenIndexToWagon.length/4){
             return Stage.Journey4;
        }else{
             return Stage.Destination;
         }
    }

    bytes32 wagonRoot; //used in merkle proof

    event Steer(uint16 indexed _wagonId, uint256 indexed _tokenId);
    event Supply(uint256 indexed _tokenId);
    event Trail(uint256 indexed _tokenId, uint8 indexed _newTrailId);
    event Ambush(uint256 indexed _tokenId);

    function steer(uint16 _wagonId, uint8[2] calldata _items, bytes1 firstLetter, uint8 _trail, bytes32[] memory _proof) public payable {
        if(msg.sender != owner) {
            //user
            require(stage() == Stage.Minting, "stage");
            require(_trail >=7 && _trail <= 14, "trail");
            //early access handling
            //if(block.timestamp < startTime + EARLY_ACCESS_TIME){
                //First day is insiders list
            //    require(DoomsdayAccess(access).hasAccess(accessProof,msg.sender),"permission");
            //}

        } else {
            //owner - giveaways
            require(stage() == Stage.Initial || stage() == Stage.Minting); //other conditions may miss
        }

        bytes32 leaf = keccak256(abi.encodePacked(_wagonId, _items[0], _items[1], firstLetter));

        //passed arguments are valid
        require(MerkleProof.verify(_proof, wagonRoot, leaf), "proof");

        //wagon has not been steered - Doomsday adds && coordinates[_cityId][0] == 0 && coordinates[_cityId][1] == 0.
        require(wagonToToken[_wagonId] == 0 && items[_wagonId][0] == 0 && items[_wagonId][1] == 0, "steered");

        //items are valid (0-12). Not strictly necessary.
        require(_items[0] < 13 && _items[1] < 13, "items");

        require(msg.value == MINT_COST, "cost");

        items[_wagonId] = _items;
        tokenIndexToWagon.push(_wagonId);
        uint _tokenId = tokenIndexToWagon.length;
        balances[msg.sender]++;
        owners[_tokenId] = msg.sender;
        wagonToToken[_wagonId] = _tokenId;
        tokenToTrail[_tokenId] = _trail;
        wagonToFirstLetter[_wagonId] = firstLetter;

        emit Steer(_wagonId, _tokenId);
        emit Transfer(address(0), msg.sender, _tokenId);
    }

    function ambush(uint _ambusherTokenId, uint _victimTokenId) public{
        require(isInJourneyStage());
        require(isValidToken(_victimTokenId),"invalidVictim");
        require(isValidToken(_ambusherTokenId),"invalidAmbusher");

        require(msg.sender == tx.origin,"no contracts");
        require(msg.sender == ownerOf(_ambusherTokenId));

        require(lastAmbushes[msg.sender] != block.number,"frequency");
        lastAmbushes[msg.sender] = block.number;

        (uint8 _supplies, uint8 _ambushes, bytes32 _lastAmbush) = getStructuralData(_victimTokenId);

        //  covered by isValidToken
        //      require(_damage <= _reinforcement,"eliminated" );

        require(tokenToTrail[_victimTokenId] == tokenToTrail[_ambusherTokenId], "sameTrail");

        require(checkVulnerable(_victimTokenId,_lastAmbush),"vulnerable");

        (,, bytes32 _inconvenienceId) = PioneersTrails(trails).currentInconveniences(tokenToTrail[_victimTokenId]);

        _inconvenienceId = encodeAmbush(_inconvenienceId);

        emit Ambush(_victimTokenId);

        if(_ambushes < _supplies){
            _ambushes++;
            setStructuralData(_victimTokenId,_supplies,_ambushes,_inconvenienceId);
        }else{
            balances[owners[_victimTokenId]]--;
            delete wagonToToken[tokenToWagon(_victimTokenId)];
            destroyed++;

            emit Transfer(owners[_victimTokenId],address(0),_victimTokenId);

            // TODO: COLLECTIBLES?????
            /*if(collectibles != address(0)){
                IDoomsdayCollectibles(collectibles).mint(owners[_tokenId],tokenToCity(_tokenId));
            }*/
        }

        payable(msg.sender).transfer(MINT_COST * MINT_PERCENT_LOOT / 100);
    }

    function changeTrail(uint _tokenId, uint8 _newTrailId) public payable {

        Stage _stage = stage();

        require(_stage == Stage.Journey1 || _stage == Stage.Journey2 || _stage == Stage.Journey3, "stage"); 
        require(ownerOf(_tokenId) == msg.sender, "owner");

        (uint8 _supplies, uint8 _ambushes, bytes32 _lastAmbush) = getStructuralData(_tokenId);
        _supplies; _ambushes;

        require(!checkVulnerable(_tokenId, _lastAmbush));

        if(_stage == Stage.Journey1){
            require(msg.value == CHANGE_TRAIL_BASE_PRICE, "cost1");
            require(_newTrailId >= 7 && _newTrailId <= 14);
            tokenToTrail[_tokenId] = _newTrailId;

        }else if(_stage == Stage.Journey2){
            require(msg.value == 2 * CHANGE_TRAIL_BASE_PRICE, "cost2");
            require(_newTrailId >= 3 && _newTrailId <= 6);
            tokenToTrail[_tokenId] = (_newTrailId*2)+1;

        }else if(_stage == Stage.Journey3){
            require(msg.value == 3 * CHANGE_TRAIL_BASE_PRICE, "cost3");
            require(_newTrailId >= 1 && _newTrailId <= 2);
            tokenToTrail[_tokenId] = (((_newTrailId*2)+1)*2)+1;

        }

        changedTrails += msg.value - (CHANGE_TRAIL_BASE_PRICE * CHANGE_TRAIL_BASE_PRICE / 100);
        
        emit Trail(_tokenId, _newTrailId);
    }

    function buySupply(uint _tokenId) public payable {

        Stage _stage = stage();
        bool isInJourney = isInJourneyStage();

        require(isInJourney || _stage == Stage.Minting , "stage"); 
        require(ownerOf(_tokenId) == msg.sender, "owner");

        (uint8 _supplies, uint8 _ambushes, bytes32 _lastAmbush) = getStructuralData(_tokenId);

        if(isInJourney)
            require(!checkVulnerable(_tokenId,_lastAmbush), "vulnerable");

        require(msg.value == (2 ** _supplies) * MINT_COST, "cost"); //TODO: Il prezzo base è il MINT_COST???

        setStructuralData(_tokenId,_supplies+1,_ambushes,_lastAmbush);

        boughtSupplies += msg.value - (MINT_COST * MINT_PERCENT_LOOT / 100);

        emit Supply(_tokenId);
    }

    function settleDown(uint _tokenId) public{
        Stage _stage = stage();
        bool isInJourney = isInJourneyStage();
        require(isInJourney || _stage == Stage.Minting,"stage");

        require(ownerOf(_tokenId) == msg.sender,"owner");

        if(isInJourney)
            require(!isVulnerable(_tokenId),"vulnerable");

        uint wagonCount = tokenIndexToWagon.length;

        uint fromPool =
            //Winner fee from mints less evacuated funds
                ((MINT_COST * wagonCount * MINT_PERCENT_PRIZE / 100 - settledFunds)
            //Divided by remaining tokens
                / totalSupply())
            //Multiplied by (3+(0.9 * (destroyed / cities)) /4
                * (10000000000 + ( 29000000000 * destroyed / wagonCount  ))  / 40000000000;


        //Also give them the admin fee
        uint toWithdraw = fromPool + getSettlementRebate(_tokenId);

        balances[owners[_tokenId]]--;
        delete wagonToToken[tokenToWagon(_tokenId)];
        destroyed++;

        //Doesnt' include admin fees in settledFunds
        settledFunds += fromPool;

        emit Transfer(owners[_tokenId],address(0),_tokenId);

        /*if(collectibles != address(0)){
            IDoomsdayCollectibles(collectibles).mint(owners[_tokenId],tokenToCity(_tokenId));
        }*/ //TODO: COLLECTIBLES???

        payable(msg.sender).transfer(toWithdraw);
    }

    uint ownerWithdrawn;
    bool winnerWithdrawn;

    function winnerWithdraw(uint _winnerTokenId) public{
        require(stage() == Stage.Destination,"stage");
        require(isValidToken(_winnerTokenId),"invalid");

        // Implicitly makes sure its the right token since all others don't exist
        require(msg.sender == ownerOf(_winnerTokenId),"ownerOf");
        require(!winnerWithdrawn,"withdrawn");

        winnerWithdrawn = true;

        uint toWithdraw = winnerPrize(_winnerTokenId);
        if(toWithdraw > address(this).balance){
            //Catch rounding errors
            toWithdraw = address(this).balance;
        }

        payable(msg.sender).transfer(toWithdraw);
    }

    function ownerWithdraw() public{
        require(msg.sender == owner,"owner");

        uint wagonCount = tokenIndexToWagon.length;

        // Dev and creator portion of all mint fees collected
        uint toWithdraw = MINT_COST * wagonCount * (MINT_PERCENT_CREATOR) / 100
            //plus supplies for creator
            + (boughtSupplies * SUPPLY_PERCENT_CREATOR / 100)
            //plus changetrails for creator
            + (changedTrails * CHANGE_TRAIL_PERCENT_CREATOR / 100)
            //less what has already been withdrawn;
            - ownerWithdrawn;

        require(toWithdraw > 0,"empty");

        if(toWithdraw > address(this).balance){
            //Catch rounding errors
            toWithdraw = address(this).balance;
        }
        ownerWithdrawn += toWithdraw;

        payable(msg.sender).transfer(toWithdraw);
    }

    function currentPrize() public view returns(uint){
        uint wagonCount = tokenIndexToWagon.length;
            // 85% of all mint fees collected
            return MINT_COST * wagonCount * MINT_PERCENT_PRIZE / 100
            //minus fees removed
            - settledFunds
            //plus supplies * 90%
            + (boughtSupplies * SUPPLY_PERCENT_PRIZE / 100)
            //plus change trail
            + (changedTrails * CHANGE_TRAIL_PERCENT_PRIZE / 100);
    }

    function winnerPrize(uint _tokenId) public view returns(uint){
        return currentPrize() + getSettlementRebate(_tokenId);
    }
    

    function getSettlementRebate(uint _tokenId) internal view returns(uint) {
        (uint8 _supplies, uint8 _ambushes, bytes32 _lastAmbush) = getStructuralData(_tokenId);
        _lastAmbush;
        return MINT_COST * (1 + _supplies - _ambushes) *  MINT_PERCENT_PRIZE / 100;
    }

    function convertItem(uint8 _item) internal pure returns(bytes1){
        bytes16 allInconveniences = "pidyjmcwhxbrq";
        return allInconveniences[_item];
    }

    function isInJourneyStage() public view returns(bool){
         return (stage() == Stage.Journey1 || stage() == Stage.Journey2 || stage() == Stage.Journey3 || stage() == Stage.Journey4 );
    }


    function checkVulnerable(uint _tokenId, bytes32 _lastAmbush) internal view returns(bool){

        (string memory _pickedLetter, string memory _pickedInconvenience, bytes32 _inconvenienceId) = PioneersTrails(trails).currentInconveniences(tokenToTrail[uint8(_tokenId)]);

        if(_lastAmbush == encodeAmbush(_inconvenienceId)) return false;

        uint16 _wagonId = tokenToWagon(_tokenId);

        return 
            wagonToFirstLetter[_wagonId] == bytes1(abi.encodePacked(_pickedLetter)) && 
            convertItem(items[_wagonId][0]) != bytes1(abi.encodePacked(_pickedInconvenience)) && 
            convertItem(items[_wagonId][1]) != bytes1(abi.encodePacked(_pickedInconvenience)); // Protetto dagli item? 
    }

    function isVulnerable(uint _tokenId) public  view returns(bool){
        (uint8 _supplies, uint8 _ambushes, bytes32 _lastAmbush) = getStructuralData(_tokenId);
        _supplies;_ambushes;

        return checkVulnerable(_tokenId,_lastAmbush);
    }


    ///ERC 721:
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        if(_tokenId == 0) return false;
        return wagonToToken[tokenToWagon(_tokenId)] != 0;
    }


    function balanceOf(address _owner) external override view returns (uint256){
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public override view returns(address){
        require(isValidToken(_tokenId),"invalid");
        return owners[_tokenId];
    }


    function approve(address _approved, uint256 _tokenId) external override {
        address _owner = ownerOf(_tokenId);
        require( _owner == msg.sender                    //Require Sender Owns Token
            || authorised[_owner][msg.sender]                //  or is approved for all.
        ,"permission");
        emit Approval(_owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) external override view returns (address) {
        require(isValidToken(_tokenId),"invalid");
        return allowance[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return authorised[_owner][_operator];
    }


    function setApprovalForAll(address _operator, bool _approved) external override {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public override {

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = ownerOf(_tokenId);

        require ( _owner == msg.sender             //Require sender owns token
        //Doing the two below manually instead of referring to the external methods saves gas
        || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[_owner][msg.sender]          //or is approved for all
        ,"permission");
        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        if(isInJourneyStage()){
            require(!isVulnerable(_tokenId),"vulnerable");
        }

        emit Transfer(_from, _to, _tokenId);


        owners[_tokenId] =_to;

        balances[_from]--;
        balances[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }

    }

    /**The require Solidity function guarantees validity of the condition(s) passed as parameter that cannot be detected before execution. It checks inputs, contract state variables and return values from calls to external contracts.
    Solidity manages errors by using state-reverting exceptions. These exceptions revert all modifications done to the state in the current call, including all sub-calls. Additionally, it can show an error to the caller if a string is passed as parameter.
    Require is convenient for checking inputs of a function especially in modifiers for example. A common use case for example is to check if the caller of the function is really the owner of the smart contract:*/

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


    function name() external override view returns (string memory _name){
        return __name;
    }

    function symbol() external override view returns (string memory _symbol){
        return __symbol;
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory){ //TODO: tokenUri?
        require(isValidToken(_tokenId),'tokenId');

        // return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }

    function totalSupply() public view returns (uint256){
        return tokenIndexToWagon.length - destroyed;
    }


    function setExternalData(string calldata _newBase, string calldata _newSuffix) public{
        require(msg.sender == owner,"owner");

        __uriBase   = bytes(_newBase);
        __uriSuffix = bytes(_newSuffix);
    }

    //===165 Implementation
    mapping (bytes4 => bool) internal supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) external override view returns (bool){
        return supportedInterfaces[interfaceID];
    }
    ///==End 165
    
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

pragma solidity ^0.8.4;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./IPioneers.sol";


pragma solidity >=0.8.8 < 0.9.0;

contract PioneersTrails is KeeperCompatibleInterface{

    uint constant INCONVENIENCE_BLOCK_INTERVAL = 255;

    mapping(uint8 => bytes12) public trailToEncodedInconveniences;

    // Errors def
    error PIONEERS_EmptyTrail();
    error PIONEERS_NoUpkeepNeeded();

    address pioneers;
    
    constructor(){
        pioneers = msg.sender;
    }

    function setPioneers(address _pioneers) public{
        require(msg.sender == pioneers,"sender");
        pioneers = _pioneers;
    }

    /** Convert given _baseTrailId to an ancestor trail ID based on current stage. */
    function getTrailIdByStage(uint8 _baseTrailId,bool debug) public view returns(uint8 _updatedTrailId){
        

        if (debug){
            return _baseTrailId;
        }
        else{
            if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey1)
                return _baseTrailId;
            else if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey2)
                return (_baseTrailId - 1) / 2;
            else if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey3) 
            {
                uint8 parent = (_baseTrailId - 1) / 2;
                return (parent - 1) / 2;
            }
            else if(IPioneers(pioneers).stage() == IPioneers.Stage.Journey4)
                return 0;
        }

    }

    // //DEBUG PURPOSES OVERRIDE
    // function stage() public pure override returns(Stage){
    //     return Stage.Journey1;
    // }

    function getEncodedInconveniencesByTrail(uint8 _baseTrailId) public view returns(bytes12){
        return trailToEncodedInconveniences[getTrailIdByStage(_baseTrailId,false)];
    }

    /** Decode bytes-written inconveniences into array of string (single-char). */
    function getDecodedInconveniencesByTrail(uint8 _baseTrailId) public view returns (string[] memory _decodedInconveniences,uint256 _size){
        string[] memory inconveniences = new string[](12);
        
        uint8 updatedTrailId = getTrailIdByStage(_baseTrailId,false);

        bytes12 inconveniencesBytes = trailToEncodedInconveniences[updatedTrailId];

        if(inconveniencesBytes.length == 0)
            revert PIONEERS_EmptyTrail();

        uint size = 0;

        for(uint i = 0 ; i < 12; i++)
            if(inconveniencesBytes[i] != 0){
                inconveniences[i] = string(
                 abi.encodePacked( inconveniencesBytes[i] )
                );
                size++;
            }

        return (inconveniences,size);
    }

    /** Get the current active inconvenience for the given trail and hash. */
    function getCurrentTrailInconvenience(uint8 _baseTrailId, int _currentHash) public view returns (string memory _inconvenience){
        string[] memory allTrailInconveniences;
        (allTrailInconveniences,) = getDecodedInconveniencesByTrail(_baseTrailId);

        int validLength = 0;

        for(uint i = 0; i <= allTrailInconveniences.length && bytes(allTrailInconveniences[i]).length != 0 ; i++)
            validLength++;

        return allTrailInconveniences[ uint(_currentHash % validLength) ];
    }

    /** Debug function for pseudo-random number. */
    function getRandomNumber(bool _isDebug) public view returns (uint _rand){
        if(!_isDebug){
            uint eliminationBlock = block.number - (block.number % INCONVENIENCE_BLOCK_INTERVAL) + 1;
            return uint(blockhash(eliminationBlock))%uint(type(int).max);
        }
        else
            return uint(keccak256(abi.encodePacked(
                block.timestamp, 
                blockhash(block.number)
            )));
    }

    function removeByteFromBytes16(bytes16 data, uint index) public pure returns(bytes16){
        bytes memory tmp = new bytes(16);
        uint found = 0;
        for(uint i = 0; i < 16; i++){
            if(i != index){
                tmp[i-found] = data[i];
            }
            else found++;
        }
        return bytes16(abi.encodePacked(tmp));
    }

    /** When a stage is completed, this function calculates inconveniences for new trails. This must reward the caller.  
    The number generation seed must be obtained from Chainlink VRF (or blockhash).
    In the current version, the generation is made by block.timestamp 
    CURRENTLY IT'S PUBLIC AND IT'S A SECURITY PROBLEM. */

    function generateInconveniencesForNextTrails(uint8 nextStage) public{
        
        // pidyjmcwhxbrq
        bytes16 allInconveniences = "pidyjmcwhxbrq";

        IPioneers.Stage _nextStage = IPioneers.Stage(nextStage);

        if(_nextStage == IPioneers.Stage.Journey1){
            if(trailToEncodedInconveniences[7].length == 0)
                for(uint i = 7; i <= 14; i++){
                    bytes memory temp = new bytes(12);
                    bytes16 availableInconveniences = allInconveniences;
                    uint removedInconveniences = 0;
                    for(uint j = 0; j < 3; j++){
                        uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                        temp[j] = availableInconveniences[rand];
                        removedInconveniences++;
                        availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                    }
                    trailToEncodedInconveniences[uint8(i)] = bytes12(abi.encodePacked(temp[0],temp[1],temp[2]));
                }
        }
                
        else if(_nextStage == IPioneers.Stage.Journey2){
            if(trailToEncodedInconveniences[3].length == 0)
                for(uint i = 3; i <= 6; i++){
                    bytes memory temp = new bytes(12);
                    bytes16 availableInconveniences = allInconveniences;
                    uint removedInconveniences = 0;
                    for(uint j = 0; j < 6; j++){
                        uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                        temp[j] = availableInconveniences[rand];
                        removedInconveniences++;
                        availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                    }

                    trailToEncodedInconveniences[uint8(i)] = bytes12(temp);
                }
        }
            
        else if(_nextStage == IPioneers.Stage.Journey3)
        {
            if(trailToEncodedInconveniences[1].length == 0)
                for(uint i = 1; i <= 2; i++){
                    bytes memory temp = new bytes(12);
                    bytes16 availableInconveniences = allInconveniences;
                    uint removedInconveniences = 0;
                    for(uint j = 0; j < 9; j++){
                        uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                        temp[j] = availableInconveniences[rand];
                        removedInconveniences++;
                        availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                    }

                    trailToEncodedInconveniences[uint8(i)] = bytes12(temp);
                }
        }
        else if(_nextStage == IPioneers.Stage.Journey4){
            if(trailToEncodedInconveniences[0].length == 0)
            {
                bytes memory temp = new bytes(12);
                bytes16 availableInconveniences = allInconveniences;
                uint removedInconveniences = 0;
            
                for(uint j = 0; j < 12; j++){
                    uint rand = getRandomNumber(true) % (13 - removedInconveniences);
                    temp[j] = availableInconveniences[rand];
                    removedInconveniences++;
                    availableInconveniences = removeByteFromBytes16(availableInconveniences, rand);
                }
                trailToEncodedInconveniences[0] = bytes12(temp);
            }
        }
            
    } 

    function currentInconveniences(uint8 _baseTrailId) public view returns (string memory _pickedLetter, string memory _pickedInconvenience, bytes32 _inconvenienceId)
    {       
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWYZ";

        uint eliminationBlock = block.number - (block.number % INCONVENIENCE_BLOCK_INTERVAL) + 1;
        int hash = int(uint(blockhash(eliminationBlock))%uint( type(int).max) );
        // int hash = int(getRandomNumber(true));

        uint rand = uint(hash) % 25;
        string memory pickedLetter = string( abi.encodePacked(alphabet[rand]) );

        uint256 size;
        string[] memory inconveniences;
        (inconveniences, size) = getDecodedInconveniencesByTrail(_baseTrailId);
        rand = uint(hash) % size;
        string memory pickedInconvenience = inconveniences[rand];

        return(pickedLetter, pickedInconvenience, blockhash(eliminationBlock));
    }

    

    //===Chainlink Keepers Implementation

    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        IPioneers.Stage _stage = IPioneers(pioneers).stage();
        bool trailInconveniencesNotGenerated = false;
        
        if(_stage == IPioneers.Stage.Journey1)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(7).length == 0;
        else if(_stage == IPioneers.Stage.Journey2)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(3).length == 0;
        else if(_stage == IPioneers.Stage.Journey3)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(1).length == 0;
        else if(_stage == IPioneers.Stage.Journey4)
            trailInconveniencesNotGenerated = getEncodedInconveniencesByTrail(0).length == 0;

        upkeepNeeded = trailInconveniencesNotGenerated;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded,) = checkUpkeep("");

        if(!upkeepNeeded)
            revert PIONEERS_NoUpkeepNeeded();
        else
        {
            generateInconveniencesForNextTrails(uint8(IPioneers(pioneers).stage()));
        }
    }

    //==End Chainlink Keepers
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
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPioneers {

    enum Stage {Initial, Minting, Journey1, Journey2, Journey3, Journey4, Destination }

    function stage() external view returns(Stage);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}