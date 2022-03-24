/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

contract Transactions {
    uint256 transactionCount;

    event Transfer (address from, address receiver, uint amount, uint256 timestamp, string lati, string longi, string date );

    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        uint256 timestamp;
        string lati;
        string longi;
        string date;
    }

    TransferStruct[] transactions;
        //memory: addittional data add to that blockchain
    function addToBlockchain(address payable receiver, uint amount, string memory lati, string memory longi, string memory date) public {
        transactionCount += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, block.timestamp, lati, longi, date));

        emit Transfer(msg.sender, receiver, amount, block.timestamp, lati, longi, date);
    }
    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }
    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }
}