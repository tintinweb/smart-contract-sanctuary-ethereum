pragma solidity ^0.4.22;

import "../provableAPI_0.4.25.sol";

contract DieselPrice is usingProvable {

    uint public dieselPriceUSD;

    event LogNewDieselPrice(string price);
    event LogNewProvableQuery(string description);

    constructor()
        public
    {
        update(); // First check at contract creation...
    }

    function __callback(
        bytes32 _myid,
        string memory _result
    )
        public
    {
        require(msg.sender == provable_cbAddress());
        emit LogNewDieselPrice(_result);
        dieselPriceUSD = parseInt(_result, 3); // Let's save it as cents...
        // Now do something with the USD Diesel price...
    }

    function update()
        public
        payable
    {
        emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
        provable_query("URL", "BAE16K4dwM8i8w0yp7gBvrhuBR+IqQe4Gtd15fIK99b0kzYpyj6TTRlYEBCHWg3AErtss4hDpAooaOJ5BRi6uhTWqPoFxwg1yOS40/vobeQnEe5usMWZt2WdKyxvx285CAP8zB4ZcxN9pnhMHH43yCZGgSy/cUnPmUr2PjdU/gtUIYn9lU5b/XHwznmZ69/cfpHK2FDdgQ9H3+NJJBmnqL1VVDpu17JY+nUBZx8KAdsWA1kd5sPXtYxa");
    }
    }