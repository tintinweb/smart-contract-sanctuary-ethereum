/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract InvestTech {
    uint public plDivideFactor = 100;

    mapping(uint256 => uint256) dateToPl;
    address public administrator;

    struct PL {
        uint256 pl;
        bool isSet;
    }

    constructor() {
        administrator = msg.sender;
    }

    function getPlByDate(uint256 _date) public view returns (uint _pl) {
        //verificar o que é retornado caso o mapeamento não existe e fazer
        //um tratamento aqui, caso seja necessário.
        _pl = dateToPl[_date];
    }

    function addPlByDate(uint _date, uint pl) public {
        require (
            msg.sender == administrator,
            "Only the administrator can add a new PL"
        );
        // require (
            //verificar se o valor na data específica já foi inserido previamente,
            // dateToPl[_date].address != address(0),
            // "You cannot change a PL's value"
        // );

        dateToPl[_date] = pl;
    }

    

}