/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// pragma solidity ^0.8.7; - Versiune cel putin la fel de noua
// pragma solidity >=0.8.7 < 0.9.0; - Versiune in range-ul dat, mai mare sau egal si mai mic strict!

contract SimpleStorage {
  uint256 public number;
  // people public person = people({number: 5, name: "Alex"});

  struct people {
    uint256 number;
    string name;
  }

  mapping(string => uint256) public nameToNumber;

  // uint256[3] public numbers;
  people[] public data;

  // calldata, memory, storage
  // storage raman tot timpul
  // memory se sterge dupa functie
  // calldata la fel ca memory, dar nu am voie sa modific variabila(const)
  // la variabile simple nu trebuie speicificat, doar la array, struct si mapping
  // nu pot pune storage la _name ca isi da seama ca nu e ok

  function addPerson(string memory _name, uint256 _number) public {
    // _name = "cat";
    // people memory newPerson = people({number: _number, name: _name}); - explicit
    // people memory newPerson = people(_number, _name);
    data.push(people(_number, _name));
    nameToNumber[_name] = _number;
  }

  function store(uint256 _number) public virtual {
    number = _number;
    retrieve();
  }

  // view, pure <=> Nu se pot modifica lucruri, doar accesa, dar nu se cheltuie nimic ca nu fac modificari
  // Daca o alta functie acceseaza aceasta functie si modifica ceva, atunci se plateste costul si pentru functia view,pure
  function retrieve() public view returns (uint256) {
    return number;
  }
}