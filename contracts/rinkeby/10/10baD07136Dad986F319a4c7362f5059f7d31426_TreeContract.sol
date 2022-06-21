//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./nfTokenEnumerable.sol";
import "./auctionContract.sol";
import "./pausable.sol";

// хранение. Какие атрибуты храним - поколение, отец, мать? пауза в скрещивании - нет?
// метод сохранить в блокчейне (createTree) - платный?? -- сделать переменную с ценой, метод на просмотр(публичный), метод на установку
// скрещивание, реализуем метод, потом решим использовать его или нет
// аукцион
// аренда
// покупка

// создание первого поколения. сколько штук? отдельный метод!!! - создание никак не ограничено
// как перевести эфир из контракта???++


contract TreeContract is NFTokenEnumerable, Pausable {
    /*** EVENTS ***/
    event Creation(address owner, uint64 treeId);

    /*** DATA TYPES ***/
    SaleClockAuction public saleAuction;

    struct Tree {
        uint64 timestamp;
        uint64 id;
        // uint8[20][30] dna;
        uint8  dna;
        uint64 generation;
        uint32 matronId;
        uint32 sireId;
    }

    // Cost (in wei) of the tree
    uint256 public treeCost = 1000000000000000;
    address public treeViewer;

    /*** STORAGE ***/
    Tree[] trees;

    constructor() {
        treeViewer = msg.sender;
    }

    function withdrawBalance(address payable _to, uint256 _amount) external onlyOwner {
        require(_to != address(0));
        _to.transfer(_amount);
    }

    function setTreeCost(uint256 _treeCost) external onlyOwner {
        treeCost = _treeCost;
    }

    function setTreeViewer(address _treeViewer) external onlyOwner {
        treeViewer = _treeViewer;
    }

    function createTree(
        // uint8[20][30] memory _dna,
        uint8  _dna,
        uint64 _generation,
        uint32 _matronId,
        uint32 _sireId,
        address _owner
    )
    external
    payable
    {
        uint256 value = msg.value;
        require(value >= treeCost);

        // _createTree(_dna, _generation, _matronId, _sireId, msg.sender);
        _createTree(_dna, _generation, _matronId, _sireId, _owner);

        uint256 change = value - treeCost;
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }
    }

    function treeCount()
    external
    view
    returns (uint256)
    {
        return tokens.length;
    }

    /// @dev Sets the reference to the sale auction.
    /// @param _address - Address of sale contract.
    function setSaleAuctionAddress(address _address) external onlyOwner {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

        require(candidateContract.isSaleClockAuction());

        // Set the new contract address
        saleAuction = candidateContract;
    }

    /// @dev Transfers the balance of the sale auction contract
    /// to the TreeContract contract.
    function withdrawAuctionBalance() external onlyOwner {
        saleAuction.withdrawBalance();
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(idToOwner[_tokenId] == msg.sender, "sender is not token owner");

//        require(_startingPrice == uint256(uint128(_startingPrice)));
//        require(_endingPrice == uint256(uint128(_endingPrice)));
//        require(_duration == uint256(uint64(_duration)));
        require(_startingPrice >= _endingPrice);

        _approve(_tokenId, address(saleAuction));

        saleAuction.createAuction(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function getTreeData(uint64 _id)
    public
    view
    // returns (uint64, uint64, uint8[20][30] memory, uint64, uint32, uint32){
    returns (uint64, uint64, uint8, uint64, uint32, uint32){
        uint256 tokenIndex = idToIndex[_id];
        require(tokenIndex < tokens.length, INVALID_INDEX);
        // require(
        //     msg.sender == owner ||
        //     msg.sender == treeViewer ||
        //     msg.sender == idToOwner[_id],
        //     "018001"
        // );

        Tree memory _tree = trees[tokenIndex];

        return (
            _tree.timestamp,
            _tree.id,
            _tree.dna,
            _tree.generation,
            _tree.matronId,
            _tree.sireId
        );
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        idToApproval[_tokenId] = _approved;
    }

    // function _createTree(uint8[20][30] memory _dna, uint64 _generation, uint32 _matronId, uint32 _sireId, address _owner)
    function _createTree(uint8 _dna, uint64 _generation, uint32 _matronId, uint32 _sireId, address _owner)
    internal
    {
        Tree memory _tree = Tree({
            timestamp: uint64(block.timestamp),
            id: uint64(trees.length + 1),
            dna: _dna,
            generation: _generation,
            matronId: _matronId,
            sireId: _sireId
        });

        trees.push(_tree);

//        _mint(address(this), areas.length);
//        _addNFToken(address(this), areas.length);
        super._mint(_owner, trees.length);
//        _addNFToken(msg.sender, areas.length);

        // create event!!!
        emit Creation(msg.sender, _tree.id);
    }

    receive() external payable {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://opensea-creatures-api.herokuapp.com/api/creature/";
    }

    // function tokenURI() public pure returns (string memory) {
    //     return "https://opensea-creatures-api.herokuapp.com/api/creature/1";
    // }

    function tokenURI() public pure returns (string memory) {
        return "https://opensea-creatures-api.herokuapp.com/api/creature/";
    }

    // function tokenURI() public pure returns (string memory) {
    //     return "https://storage.googleapis.com/opensea-prod.appspot.com/creature/1.png";
    // }

}