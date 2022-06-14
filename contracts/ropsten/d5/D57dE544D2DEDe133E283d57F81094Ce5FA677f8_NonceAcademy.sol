// SPDX-License-Identifier: GPL-3.0

// Nonce Academy Registration Contract

pragma solidity ^0.8.14;


contract NonceAcademy {

    struct Academy{
        string name;
        string slogan;
        string logoURI;
        string website;
        string discord;
        string twitter;
    }

    Academy public nonceAcademy;

    constructor(){
        nonceAcademy = Academy("Nonce Academy", "We Are Decentralizing Code, App, World", "https://ipfs.io/ipfs/QmTagzz5xwCjPDwq4T3rYjUV2jiZzpNt7tTV5Mtpd93794?filename=nonce-academy.svg", "https://nonce.academy", "https://dsc.gg/nonceacademy", "https://twitter.com/nonceacademy"); 
    }

}