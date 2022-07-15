pragma solidity ^0.4.19;

import "./NFTERC721.sol";

// solium-disable-next-line no-empty-blocks
contract NFTCore is NFTERC721 {
    struct NFTItem {
        uint256 genes;
        uint256 bornAt;
        uint32 matronId;
        uint32 sireId;
        uint8 breedCount;
    }

    NFTItem[] nfts;

    event NFTSpawned(
        uint256 indexed _axieId,
        address indexed _owner,
        uint256 _genes
    );
    event NFTRebirthed(uint256 indexed _axieId, uint256 _genes);

    constructor() public {
        nfts.push(NFTItem(0, now, 0, 0, 0)); // The void NFTItem
        nfts.push(NFTItem(0, now, 0, 0, 0)); // The void NFTItem
        nfts.push(NFTItem(0, now, 0, 0, 0)); // The void NFTItem
        nfts.push(NFTItem(0, now, 0, 0, 0)); // The void NFTItem
        nfts.push(NFTItem(0, now, 0, 0, 0)); // The void NFTItem
        whitelistedSpawner[msg.sender] = true;

        whitelistedMarketplace[
            0x1E0049783F008A0085193E00003D00cd54003c71
        ] = true;
        _spawnNFT(
            0x3535350e0e0e1010101616160c0c0c1a1a1a18181818181802,
            msg.sender,
            0,
            0
        );
        _spawnNFT(
            0x1616161515150d0d0d3636360c0c0c17171718181836363602,
            msg.sender,
            0,
            0
        );
    }

    function getNFT(uint256 _axieId)
        external
        view
        mustBeValidToken(_axieId)
        returns (
            uint256, /* _genes */
            uint256, /* _bornAt */
            uint256,
            uint256,
            uint256
        )
    {
        NFTItem storage _axie = nfts[_axieId];
        return (
            _axie.genes,
            _axie.bornAt,
            uint256(_axie.matronId),
            uint256(_axie.sireId),
            uint256(_axie.breedCount)
        );
    }

    function spawnNFTBreed(
        uint256 _genes,
        address _owner,
        uint256 matronId,
        uint256 sireId
    )
        external
        onlySpawner
        mustBeValidToken(matronId)
        mustBeValidToken(sireId)
        returns (uint256)
    {
        require(
            nfts[matronId].breedCount < 7,
            "nfts[matronId].breedCount < 7"
        );
        require(nfts[sireId].breedCount < 7, "nfts[sireId].breedCount < 7");
        nfts[matronId].breedCount++;
        nfts[sireId].breedCount++;
        return _spawnNFT(_genes, _owner, uint32(matronId), uint32(sireId));
    }

    function spawnNFT(uint256 _genes, address _owner)
        external
        onlySpawner
        returns (uint256)
    {
        return _spawnNFT(_genes, _owner, 0, 0);
    }

    function rebirthNFT(uint256 _axieId, uint256 _genes)
        external
        onlySpawner
        mustBeValidToken(_axieId)
    {
        NFTItem storage _axie = nfts[_axieId];
        _axie.genes = _genes;
        _axie.bornAt = now;
        emit NFTRebirthed(_axieId, _genes);
    }

    function _spawnNFT(
        uint256 _genes,
        address _owner,
        uint32 matronId,
        uint32 sireId
    ) private returns (uint256 _axieId) {
        NFTItem memory _axie = NFTItem(_genes, now, matronId, sireId, 0);
        _axieId = nfts.push(_axie) - 1;
        _mint(_owner, _axieId);
        emit NFTSpawned(_axieId, _owner, _genes);
    }
}