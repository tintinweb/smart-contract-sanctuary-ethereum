// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract myERC1155 {
    string private _uri;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    constructor(string memory uri_) {
        _setURI(uri_);
    }
    function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function transferFrom(address from, address to, uint256 id, uint256 amount) public {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);
    }


    function mint(address to, uint256 id, uint256 amount) public {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
    }

    function burn(address from, uint256 id, uint256 amount) public {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }


    function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) public {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }


    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {}


    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./myERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TicketsEvents is myERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;
    Counters.Counter public ticketsForSaleLeft;

    struct TicketNFT {
        string ticketName;
        uint price;
        bool forSale;
        address owner;
    }
    mapping(uint => TicketNFT) public idToTicket;

    constructor(string memory _ticketName, uint _price, uint256 _amount) myERC1155("TiketsNFT") {
        ticketsForSaleLeft._value = _amount;
        mintTikets(_ticketName, _price, _amount);
     }

    function mintTikets(string memory _ticketName, uint _price, uint _amount) public {
        uint ticketId = tokenId.current();
        for(uint i=1; i<=_amount; i++) {
            idToTicket[ticketId] = TicketNFT(_ticketName, _price, true, msg.sender);
            tokenId.increment();
        }
    }

    function buyTicket(uint _id) payable public {
        require(ticketsForSaleLeft._value > 0, "Sold out");
        require(idToTicket[_id].forSale == true, "Ticket is not for sale");
        require(msg.value == idToTicket[_id].price, "Wrong ticket price");
        address owner = idToTicket[_id].owner;
        transferFrom(owner, msg.sender, _id, 1);
        payable(owner).transfer(msg.value);
        idToTicket[_id].forSale = false;
        idToTicket[_id].owner = msg.sender;
        ticketsForSaleLeft.decrement();
    }

    function sellTicket(uint _id) public {
        require(idToTicket[_id].owner == msg.sender, "You are not owner of the ticket");
        idToTicket[_id].forSale = true;
        ticketsForSaleLeft.increment();
    }

    function getTicketDetails(uint _id) public view returns (TicketNFT memory) {
        return idToTicket[_id];
    }

    function getTicketsForSaleLeft() public view returns (uint256) {
        return ticketsForSaleLeft._value;
    }

}