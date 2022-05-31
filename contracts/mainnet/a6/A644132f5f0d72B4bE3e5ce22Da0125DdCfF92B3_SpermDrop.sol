// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./IERC721.sol";
import "./Ownable.sol";

abstract contract PhaseTwoContract {
    function mintTransfer(address to, uint num) public virtual;
}

contract SpermDrop is Ownable, ERC1155 {
    bool public isClaimingOpen;
    bool public isPhaseTwoLive;

    uint internal immutable VIAL_TOKEN_ID = 69;
    uint internal immutable MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IERC721 spermGameContract;
    PhaseTwoContract phaseTwoContract;

    uint[] public claimedTokenIds = new uint[](35);
    uint[] public fertilizedTokenIds = new uint[](35);

    constructor(string memory uri, address spermGameContractAddress) ERC1155(uri) {
        isClaimingOpen = true;
        spermGameContract = IERC721(spermGameContractAddress);
        fertilizedTokenIds[0] = 284904090933172363851828178089962979291276210615786860444928520148817544235;
        fertilizedTokenIds[1] = 7237005584072300303562902106435682269767449283491186732717862496114183249920;
        fertilizedTokenIds[2] = 414288714535886305823005251211638312678396075680443203073280;
        fertilizedTokenIds[3] = 14193441368756812658150572982498243420730590411724791690373492611590787236;
        fertilizedTokenIds[4] = 111210191378528134093956457614245748633675670291214581752921627557892;
        fertilizedTokenIds[5] = 2544261285618089366071395133368153071561987273585144766297479459388138726432;
        fertilizedTokenIds[6] = 4523128485832667123600479219406915366359104018849908714910265626852807016448;
        fertilizedTokenIds[7] = 13817395576550546143798711704427130313927062757492740981677942708109320;
        fertilizedTokenIds[8] = 3561301246584797962462627906544636702077200724313405754364146456322899972;
        fertilizedTokenIds[9] = 3537687571660157946233675981384454647391435045373880563229930457797757507;
        fertilizedTokenIds[10] = 57897812113604094441082049139500858469756049087703082731870490917434585810434;
        fertilizedTokenIds[11] = 1447307013765432847746407376748470682208;
    }

    // NOTE: Works best if tokenIds are ordered ascending
    function claim(uint[] calldata tokenIds) external {
        require(isClaimingOpen, "Claiming is not open.");

        uint[] memory claimBitMapList = claimedTokenIds;
        uint claimPartitionIndex = MAX_INT;
        uint claimPartition;
        uint[] memory fertilizedBitMapList = fertilizedTokenIds;
        uint fertilizedPartitionIndex = MAX_INT;
        uint fertilizedPartition;
        uint alreadyClaimedCount = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint tokenId = tokenIds[i];
            require(spermGameContract.ownerOf(tokenId) == msg.sender, "Must be owner of token to claim.");
            if ((tokenId / 256) != claimPartitionIndex) {
                claimPartitionIndex = tokenId / 256;
                claimPartition = claimBitMapList[claimPartitionIndex];
                fertilizedPartitionIndex = claimPartitionIndex;
                fertilizedPartition = fertilizedBitMapList[fertilizedPartitionIndex];
            }
            if ((claimPartition & (1 << (tokenId % 256))) != 0) {
                alreadyClaimedCount++;
                continue;
            }
            if (!isEggTokenId(tokenId)) {
                require((fertilizedPartition & (1 << (tokenId % 256))) != 0, "At least one token is not eligible to claim.");
            }

            setClaimed(tokenId);
        }
        require(alreadyClaimedCount < tokenIds.length, "All tokens have already been claimed.");

        _mint(msg.sender, VIAL_TOKEN_ID, (tokenIds.length - alreadyClaimedCount), "");
    }

    function exchangeForPhaseTwo(uint num) external {
        require(isPhaseTwoLive, "Phase Two is not live yet.");
        require(balanceOf(msg.sender, VIAL_TOKEN_ID) >= num, "Doesn't own enough tokens.");
        _burn(msg.sender, VIAL_TOKEN_ID, num);
        phaseTwoContract.mintTransfer(msg.sender, num);
    }

    function setPhaseTwoContractAddress(address addr) external onlyOwner {
        isPhaseTwoLive = true;
        phaseTwoContract = PhaseTwoContract(addr);
    }

    function togglePhaseTwoLive() external onlyOwner {
        isPhaseTwoLive = !isPhaseTwoLive;
    }

    function toggleClaimingOpen() external onlyOwner {
        isClaimingOpen = !isClaimingOpen;
    }

    function setFertilized(uint tokenId) external onlyOwner {
        uint[] storage bitMapList = fertilizedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        uint bitIndex = tokenId % 256;
        bitMapList[partitionIndex] = partition | (1 << bitIndex);
    }

    function setFertilizedPartitions(uint[] calldata partitionIndices, uint[] calldata newPartitions) external onlyOwner {
        require(partitionIndices.length == newPartitions.length, "Number of indices and partitions must match.");
        for (uint i = 0; i < partitionIndices.length; i++) {
            uint partitionIndex = partitionIndices[i];
            fertilizedTokenIds[partitionIndex] = newPartitions[partitionIndex];
        }
    }

    function isFertilized(uint tokenId) external view returns (bool) {
        uint[] memory bitMapList = fertilizedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        if (partition == MAX_INT) {
            return true;
        }
        uint bitIndex = tokenId % 256;
        uint bit = partition & (1 << bitIndex);
        return (bit != 0);
    }

    function setClaimed(uint tokenId) internal {
        uint[] storage bitMapList = claimedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        uint bitIndex = tokenId % 256;
        bitMapList[partitionIndex] = partition | (1 << bitIndex);
    }

    function isClaimed(uint tokenId) external view returns (bool) {
        uint[] memory bitMapList = claimedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        if (partition == MAX_INT) {
            return true;
        }
        uint bitIndex = tokenId % 256;
        uint bit = partition & (1 << bitIndex);
        return (bit != 0);
    }

    function isEggTokenId(uint tokenId) internal pure returns (bool) {
        return (tokenId % 5) == 0;
    }

    function setURI(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }
}