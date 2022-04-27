// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./bck.sol" as BCK;
import "./bcks.sol" as BCKS;
import "./game.sol" as GAME;
import "./fert.sol" as FERT;
import "./nft721.sol" as NFT;

interface IOWNER {
    function setOwner(address to) external;

    function transferOwnership(address newOwner) external;
}

interface INFT {
    function setMiner(address new_addr, bool _value) external;
}

interface IBCK {
    function daoApprove(address dao, address spender) external;
}

interface IBCKS {
    function setMiner(address new_miner) external;
}

//一键部署合约
contract Deploy {
    address public bck;
    address public bcks;
    address public nft;
    address public game;
    address public fert;

    constructor() {
        bck = address(new BCK.ERC20(msg.sender));
        fert = address(new FERT.ERC20(msg.sender, bck));
        nft = address(new NFT.NFT());

        bcks = address(new BCKS.ERC20());
        game = address(new GAME.BCKGAME(msg.sender, bck, bcks, fert, nft));

        IBCK(bck).daoApprove(msg.sender, fert);
        IBCK(bck).daoApprove(msg.sender, game);
        INFT(nft).setMiner(game, true);
        IOWNER(nft).transferOwnership(msg.sender);
        IOWNER(game).setOwner(msg.sender);
        IOWNER(bck).setOwner(msg.sender);
        IBCKS(bcks).setMiner(game);
        IOWNER(bcks).setOwner(msg.sender);
    }
}