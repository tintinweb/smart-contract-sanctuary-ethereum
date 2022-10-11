// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface EtherID {
    function getDomain(uint domain) external returns (address, uint, uint, address, uint, uint);
    function changeDomain(uint domain, uint expires, uint price, address transfer) external; 
}


contract Minter {

    constructor() {}

    function mint(uint root_domain, uint number, address base_contract) public {
       
        EtherID etherIDInt = EtherID(base_contract);
        uint minted = 0;
        uint domain = root_domain;
        uint expires;
        uint next_domain;

        while (minted < number && domain != 1952805748) {
            (, expires, , , next_domain, ) = etherIDInt.getDomain(domain);
            if (expires < block.number) {
                etherIDInt.changeDomain(domain, 1000000000000000000, 0, msg.sender);
                minted += 1;
            }
            domain = next_domain;
        }   
    }   
}