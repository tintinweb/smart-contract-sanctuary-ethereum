pragma solidity ^0.4.22;

import "../provableAPI_0.4.25.sol";

contract DieselPrice is usingProvable {

    uint public dieselPriceUSD;

    event LogNewDieselPrice(string price);
    event LogNewProvableQuery(string description);

    constructor()
        payable
        public
    {
        provable_setCustomGasPrice(4000000000);
        update(); // First check at contract creation...
    }

    function __callback(
        
        string memory _result
    )
        public
    {
        require(msg.sender == provable_cbAddress());
        emit LogNewDieselPrice(_result);
        dieselPriceUSD = parseInt(_result, 2); // Let's save it as cents...
        // Now do something with the USD Diesel price...
    }

    function update()
        public
        payable
    {
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
        provable_query("URL", "json(https://eodhistoricaldata.com/api/real-time/TEF.MC?api_token=5bddbb6db45b91.96585960&fmt=json).close");
    }
    }