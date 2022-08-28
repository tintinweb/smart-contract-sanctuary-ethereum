// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Struct {
    // podemos crear tipos de datos mas complejos, SampleStruct1
    struct SampleStruct1 {
        uint256 id;
        uint256 value;
        string name;
        bool isCreated;
    }

    // creamos una variable publica del tipo SampleStruct1, conteniendo los tipos declarados previamente
    SampleStruct1 public sample1;

    // tenemos 3 formas de inicializar un struct que podemos ver en esta funcion
    function setSample1(
        uint256 _id,
        uint256 _value,
        string calldata _name,
        bool _isCreated
    ) public {
        // metodo 1
        sample1.id = _id;
        sample1.value = _value;
        sample1.name = _name;
        sample1.isCreated = _isCreated;

        // metodo 2
        // sample1 = SampleStruct1({
        //     id: 2,
        //     value: 2,
        //     name: "myname",
        //     isCreated: true
        // });

        // metodo 3
        // sample1 = SampleStruct1(3, 6, "myname", false);
    }
}