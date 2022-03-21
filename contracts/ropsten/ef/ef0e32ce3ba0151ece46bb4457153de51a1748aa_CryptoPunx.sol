// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './CryptoPunxBase.sol';


contract CryptoPunx is CryptoPunxBase {
    constructor()
        CryptoPunxBase(
            'CryptoPunx',
            'CPX',
            'ipfs://tbd/'
        )
    {

    }
}