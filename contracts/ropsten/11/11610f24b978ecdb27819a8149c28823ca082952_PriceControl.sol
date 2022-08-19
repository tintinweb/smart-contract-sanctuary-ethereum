/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

pragma solidity ^0.4.0;

contract AbstractPrice {
    function price(address control) constant returns(uint);
    function setPrice(address control, uint money);
}


pragma solidity ^0.4.0;

/**
 * The ENS registry contract.
 */
contract PriceControl is AbstractPrice {
    struct Record {
        uint price;
    }

    mapping(address=>Record) records;


    /**
     * Constructs a new ENS registrar.
     */
    function PriceControl() {
        records[0x0].price = 0;
    }



    /**
     * Returns the price of the specified address.
     */
    function price(address control) constant returns (uint) {
        return records[control].price;
    }

    function setPrice(address control, uint money) {
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        records[control].price = money*31556952*1e10;
    }

}