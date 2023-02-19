// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
//  __       ___ __     __    __  __     __            
// /  \\/|\ |__ /__`   |__)  /  \/  `|__/  `|__|/\|\ | 
// \__/  | \|___.__/   |__)__\__/\__,|  \__,|  /~~\ \| 

// omnesblockchain - @afonsod.eth & @gus_deps
//https://github.com/OmnesBlockchainDev
contract faucetOmnesBlockchain{

    uint public valorNoCofre;
    bool public pause;
    address owner;
    

    constructor(){
        owner = msg.sender;
    }

    function depositar()public payable{
        payable(address(this)).transfer(msg.value);
        valorNoCofre += msg.value;
    }

    function sacar()public payable paused{
        uint weizero1 = 100000000000000000 wei; //0.1 ether
        require(msg.value == 0, "nao envie valores insira 0");
        payable(msg.sender).transfer(weizero1);
        valorNoCofre -= weizero1;
    }

    function setPause(bool _pauserOudespausar) onlyOwner external{
        pause = _pauserOudespausar;
    }

    receive() external payable{
    }

    modifier paused{
        require(pause == false, "contrato esta pausado");
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "so o dono pode");
        _;
    }


}