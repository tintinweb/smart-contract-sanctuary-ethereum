// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Questo contratto ci serve per capire facilmente se Ã¨ stato urprgaded o no
// PoichÃ¨ vogliamo che questi siano proxy, qui posso vedere che non ho settato un costruttore, ciÃ² perchÃ¨ invece potremmo avere un
// qualche tipo di initializer function. Per esempio mettiamo caso che io voglia usare la funzione store come costruttore, dunque per
// farlo andrei a chiamare ciÃ² che prende il nome di initializer function (al momento in cui andiamo a fare il deploy del contratto).
// Per gli scopi del corso non ci serviremo di un initializer
contract Box {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}