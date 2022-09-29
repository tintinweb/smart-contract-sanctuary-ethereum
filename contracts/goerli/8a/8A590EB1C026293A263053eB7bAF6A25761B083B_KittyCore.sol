// SPDX-License-Identifier: LGPL-3.0-only
// We need this file for testing CryptoKitty interface in localhost/testnet since none of Kitty is available as a default in testnet.
pragma solidity 0.8.17;

contract KittyCore {
    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint64 cooldownEndBlock;
        uint32 matronId;
        uint32 sireId;
        uint32 siringWithId;
        uint16 cooldownIndex;
        uint16 generation;
    }

    uint256 public secondsPerBlock = 15;
    Kitty[] kitties;
    mapping(uint256 => address) public kittyIndexToOwner;
    mapping(address => uint256) ownershipTokenCount;
    mapping(uint256 => address) public kittyIndexToApproved;
    mapping(uint256 => address) public sireAllowedToAddress;

    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        ownershipTokenCount[_to]++;
        kittyIndexToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete sireAllowedToAddress[_tokenId];
            delete kittyIndexToApproved[_tokenId];
        }
    }

    function _createKitty(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) internal returns (uint256) {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));

        uint16 cooldownIndex = uint16(_generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }

        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            cooldownEndBlock: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: cooldownIndex,
            generation: uint16(_generation)
        });
        kitties.push(_kitty);
        uint256 newKittenId = kitties.length - 1;

        require(newKittenId == uint256(uint32(newKittenId)));

        _transfer(address(0), _owner, newKittenId);

        return newKittenId;
    }

    address public newContractAddress;

    constructor() {
        _createKitty(0, 0, 0, 0, address(0));
    }

    function getKitty(uint256 _id)
        external
        view
        returns (
            bool isGestating,
            bool isReady,
            uint256 cooldownIndex,
            uint256 nextActionAt,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        )
    {
        Kitty storage kit = kitties[_id];

        isGestating = (kit.siringWithId != 0);
        isReady = (kit.cooldownEndBlock <= block.number);
        cooldownIndex = uint256(kit.cooldownIndex);
        nextActionAt = uint256(kit.cooldownEndBlock);
        siringWithId = uint256(kit.siringWithId);
        birthTime = uint256(kit.birthTime);
        matronId = uint256(kit.matronId);
        sireId = uint256(kit.sireId);
        generation = uint256(kit.generation);
        genes = kit.genes;
    }
}