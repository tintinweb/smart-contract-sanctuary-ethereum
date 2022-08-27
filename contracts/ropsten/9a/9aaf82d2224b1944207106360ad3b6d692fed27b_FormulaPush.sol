/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
//import {globeVar} from "/../../components/global";

contract FormulaPush{
    

    struct AvailableFormula{
        string myFormula;
    }
    
    uint private _formulaID = 0;
    mapping(uint => AvailableFormula) private _availableFormulas;

    function pushFormula(string memory input) public
    {
        AvailableFormula memory availableFormula = AvailableFormula(
            input
        );
    
       
        _availableFormulas[_formulaID] = availableFormula;
        _formulaID++;
    }

    function getFormulas(uint index) public view returns (string memory)
    {
        return _availableFormulas[index].myFormula;
    }
}