/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contract/file_trade.sol



pragma solidity ^0.8.0;


contract FileShare{

    string constant VERSION = "1.0.1";

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    struct Trade {
        address from;
        address to;
        string file_hash;
        // string org_file_hash;
        string title;
        string desc;
        uint status; // 0.new; 1.file confirmd; 2.pwd sended
        string pwd;
    }

    mapping(uint256 => Trade) private trades;

    constructor() {
        _idTracker.reset();
    }

    /**
    * @dev Function to get details of trade
    */
    function newTrade(string memory file_hash, string memory title, string memory desc) public returns (
        uint256 id
    ){
        return newTradeTo(file_hash, address(0x0), title, desc);
    }

    /**
    * @dev Function to get details of trade
    */
    function newTradeTo(string memory file_hash, address to, string memory title, string memory desc) public returns (
        uint256 id
    ){
        id = _idTracker.current();
        trades[id].from = msg.sender;
        trades[id].to = to;
        trades[id].file_hash = file_hash;
        // trades[id].org_file_hash = file_hash;
        trades[id].title = title;
        trades[id].desc = desc;
        trades[id].status = 0;
        trades[id].pwd = "";
        _idTracker.increment();
        return id;
    }

    /**
    * @dev Function to get details of trade
    */
    function confirmReceive(uint256 id) public {
        require(_exists(id), "FileTrade: nonexistent trade id");
        require(trades[id].status == 0, "FileTrade: Illegal operation");
        require(trades[id].from != msg.sender, "FileTrade: from can not confirm receive");
        if(trades[id].to != address(0x0)){
            require(trades[id].to == msg.sender, "FileTrade: Only specific to can confirm");
        }else{
            trades[id].to = msg.sender;
        }
        trades[id].status = 1;
    }

    /**
    * @dev Function to get details of trade
    */
    function setPwd(uint256 id, string memory pwd) public {
        require(_exists(id), "FileTrade: nonexistent trade id");
        require(trades[id].status == 1, "FileTrade: Illegal operation");
        require(trades[id].from == msg.sender, "FileTrade: Only from can set pwd");
        
        trades[id].status = 2;
        trades[id].pwd = pwd;
    }


    /**
    * @dev Function to get details of trade
    */
    function totalTrades() public view returns (
        uint256 id
    ) {
        return _idTracker.current();
    }
    
    /**
    * @dev Function to get details of trade
    */
    function getFileHash(uint256 id) public view returns (
        string memory file_hash
    ) {
        require(_exists(id), "FileTrade: nonexistent trade id");
        return trades[id].file_hash;
    }

    /**
    * @dev Function to get details of trade
    */
    function getStatus(uint256 id) public view returns (
        uint status
    ) {
        require(_exists(id), "FileTrade: nonexistent trade id");
        return trades[id].status;
    }

    /**
    * @dev Function to get details of trade
    */
    function getreceiver(uint256 id) public view returns (
        address to
    ) {
        require(_exists(id), "FileTrade: nonexistent trade id");
        return trades[id].to;
    }

    /**
    * @dev Function to get details of trade
    */
    function getPwd(uint256 id) public view returns (
        string memory pwd
    ) {
        require(_exists(id), "FileTrade: nonexistent trade id");
        return trades[id].pwd;
    }

    function _exists(uint256 tradeId) internal view virtual returns (bool) {
        return tradeId < _idTracker.current();
    }

}