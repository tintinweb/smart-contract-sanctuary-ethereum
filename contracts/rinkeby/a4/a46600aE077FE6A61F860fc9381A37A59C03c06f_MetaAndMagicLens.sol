// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract MetaAndMagicLens {

    address public meta;
    address public heroesAddress;
    address public itemsAddress;

    function initialize(address meta_, address heroes_, address items_) external {
        require(msg.sender == _owner());

        meta          = meta_;
        heroesAddress = heroes_;
        itemsAddress  = items_;
    }

    function unstakedHeroes() external view returns (uint256[] memory unstaked){
        unstaked = new uint256[](3000 - IERC721(heroesAddress).balanceOf(heroesAddress));
        uint256 counter = 0;
        for (uint256 i = 1; i < 3000; i++) {
            unstaked[counter++] = i;
        }
    }

    function unstakedHeroesOf(address acc) external view returns (uint256[] memory unstaked) {
        unstaked = new uint256[](IERC721(heroesAddress).balanceOf(acc));
        uint256 counter = 0;
        for (uint256 i = 1; i < 3101; i++) {
            if (IERC721(heroesAddress).ownerOf(i) == acc) unstaked[counter++] = i;
        }
    }

    function stakedHeroesOf(address acc) external view returns (uint256[] memory staked) {
        uint256[] memory helper = new uint256[](3000);

        uint256 size = 0;

        for (uint256 i = 1; i < 3000; i++) {
            (address owner,,) = IMetaAndMagicLike(meta).heroes(i);
            if (owner == acc){
                helper[size++] = i;
            }
        }

        staked = new uint256[](size);
        for (uint256 i = 1; i < size; i++) {
            staked[i] = helper[i];
        } 
    }

    function itemsOfUser(address acc) external view returns(uint256[] memory items) {
        items = new uint256[](IERC721(itemsAddress).balanceOf(acc));
        uint256 counter = 0;
        for (uint256 i = 1; i < 15401; i++) {
            if (IERC721(itemsAddress).ownerOf(i) == acc) items[counter++] = i;
        }
    }

    function _owner() internal view returns (address owner_) {
        bytes32 slot = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);
        assembly {
            owner_ := sload(slot)
        }
    }
}

interface IMetaAndMagicLike {
    function heroes(uint256 id) external view returns(address owner, int16 lastBoss, uint32 highestScore);
}

interface IERC721 {
    function totalSupply() external view returns (uint256 supply); 
    function ownerOf(uint256 id) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}