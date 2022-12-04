/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Vade4ka {
    address payable public owner;

    // address payable [10] list = [0x2D9484DD54f637b6CbCCdFFA7b0e7356717b7EC3,
    //     0x3827E46F676a7986AD798C2d94f5823a5d66e2b9,
    //     0xeF9a3A3a8eB8A81D2E80453fA0EfB0Ff08E742e2,
    //     0xD79248e9e0F83a30a58fE020Fdc4B6Bd74aF26ea,
    //     0xADB71414f3b40A4B3014Cfc68d6ae1625f905fdB,
    //     0xfc72CB6415fe8aa70ea504850FbB68f8b5eCfE31,
    //     0x6567c0aFa73f8B7DC851C6D9845C82967d8d2b72,
    //     0xBeFeE984CE3592Ed538192177A3d4f53110a0912,
    //     0x825D0CC57dFb8D6C926c73af516E7205373ddB72,
    //     0xe489dd44aea144783F5AD1165061dc5963c7E6E0
    //     ];

    constructor(address payable _owner){
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function makeThis(uint amount, address[] calldata list) payable external onlyOwner {
        for (uint i = 0; i < 10; i++){
           payable(list[i]).transfer(amount);
        }
    }

    function kill() public onlyOwner {
    selfdestruct(owner);
    }

}