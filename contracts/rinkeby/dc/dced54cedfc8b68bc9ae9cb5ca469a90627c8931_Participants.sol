/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

contract Participants {

    // Chainlink bootcamp participants ;)
    
    struct People{
        string name;
        string location;
        address addr;
    }

    People[] private people;


    function addPerson(string memory _name, string memory _location) public {
        people.push(People(_name, _location, tx.origin));
    }

    function retrieve() public view returns(People[] memory){
        return people;
    }
}