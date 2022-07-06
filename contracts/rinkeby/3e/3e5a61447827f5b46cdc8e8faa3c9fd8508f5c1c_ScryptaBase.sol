//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IScryptaUpgradeableBase.sol";
import "./Ownable.sol";
import "./Initializable.sol";

contract ScryptaBase is IScryptaUpgradeableBase, Ownable, Initializable {

    string[] private _tokens; // id -> token (base64)
    mapping(uint256 => bytes20[]) private _holders; // id -> accounts
    mapping(uint256 => mapping(bytes20 => uint256)) private _balances; // id -> (account -> balance)

    function initialize(IScryptaUpgradeableBase scryptaBase) public override onlyOwner initializer {
        require(_tokens.length == 0, "ScryptaBase: the contract is already storing data and cannot be initialized");

        string[] memory tokens;
        bytes20[][] memory holders;
        uint256[][] memory balances;
        (tokens, holders, balances) = scryptaBase.state();

        for (uint256 id=0; id<tokens.length; id++) {
            _tokens.push(tokens[id]);
            _holders[id] = holders[id];
            for (uint256 i=0; i<holders[id].length; i++)
                _balances[id][holders[id][i]] = balances[id][i];
        }
    }

    function state() public view override returns (string[] memory, bytes20[][] memory, uint256[][] memory) {
        string[] memory tokens = _tokens;
        bytes20[][] memory holders = new bytes20[][](tokens.length);
        uint256[][] memory balances = new uint256[][](tokens.length);
        for (uint256 id=0; id<tokens.length; id++) {
            holders[id] = _holders[id];
            balances[id] = new uint256[](_holders[id].length);
            for (uint256 i=0; i<_holders[id].length; i++)
                balances[id][i] = _balances[id][_holders[id][i]];
        }
        return (tokens, holders, balances);
    }

    function createToken(string memory tokenData) public override onlyOwner returns (uint256) {
        _tokens.push(tokenData);
        emit TokenCreated(_tokens.length-1);
        return _tokens.length-1;
    }

    function mint(bytes20 to, uint256 id, uint256 amount) public override onlyOwner {
        require(to != 0x0, "ScryptaBase: mint to the zero address not allowed");
        _transfer(0x0, to, id, amount, false);
    }

    function mintBatch(bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts) public override onlyOwner {
        for(uint256 i = 0; i < to.length; i++)
            require(to[i] != 0x0, "ScryptaBase: mint to the zero address not allowed");
        bytes20[] memory from = new bytes20[](to.length);
        _transferBatch(from, to, ids, amounts, false);
    }

    function transfer(bytes20 from, bytes20 to, uint256 id, uint256 amount) public override onlyOwner {
        _transfer(from, to, id, amount, true);
    }

    function transferBatch(bytes20[] memory from, bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts) public override onlyOwner {
        _transferBatch(from, to, ids, amounts, true);
    }

    function burn(bytes20 from, uint256 id, uint256 amount) public override onlyOwner {
        require(from != 0x0, "ScryptaBase: burn from the zero address not allowed");
        _transfer(from, 0x0, id, amount, false);
    }

    function burnBatch(bytes20[] memory from, uint256[] memory ids, uint256[] memory amounts) public override onlyOwner {
        for(uint256 i = 0; i < from.length; i++)
            require(from[i] != 0x0, "ScryptaBase: burn from the zero address not allowed");
        bytes20[] memory to = new bytes20[](from.length);
        _transferBatch(from, to, ids, amounts, false);
    }

    function token(uint256 id) public view override returns (string memory) {
        return _tokens[id];
    }

    function holdersOf(uint256 id) public view override returns (bytes20[] memory) {
        return _holders[id];
    }

    function balanceOf(uint256 id, bytes20 holder) public view override returns (uint256) {
        return _balances[id][holder];
    }

    function _transfer(bytes20 from, bytes20 to, uint256 id, uint256 amount, bool safe) private {
        require(amount > 0, "ScryptaBase: amount cannot be zero");
        require(!safe || from != 0x0, "ScryptaBase: transfer from the zero address not allowed");
        require(!safe || to != 0x0, "ScryptaBase: transfer to the zero address not allowed");
        require(from == 0x0 || _balances[id][from] >= amount, "ScryptaBase: insufficient balance for transfer");

        if (to != 0x0) {
            _balances[id][to] += amount;
            _addHolderOf(id, to);
        }
        if (from != 0x0) {
            _balances[id][from] -= amount;
            if (_balances[id][from] == 0)
                _removeHolderOf(id, from);
        }

        emit TransferExecuted(from, to, id, amount);
    }

    function _transferBatch(bytes20[] memory from, bytes20[] memory to, uint256[] memory ids, uint256[] memory amounts, bool safe) private {
        require(from.length > 0, "ScryptaBase: no transfers to perform");
        require(from.length == to.length && to.length == ids.length && ids.length == amounts.length,
            "ScryptaBase: all input arrays must have the same number of elements"
        );
        for (uint256 i=0; i<from.length; i++)
            _transfer(from[i], to[i], ids[i], amounts[i], safe);
    }

    function _findHolderOf(uint256 id, bytes20 holder) private view returns(bool, uint256) {
        for (uint256 i=0; i<_holders[id].length; i++) {
            if (_holders[id][i] == holder)
                return (true, i);
        }
        return (false, 0);
    }

    function _addHolderOf(uint256 id, bytes20 holder) private {
        (bool found,) = _findHolderOf(id, holder);
        if (!found)
            _holders[id].push(holder);
    }

    function _removeHolderOf(uint256 id, bytes20 holder) private {
        (bool found, uint256 pos) = _findHolderOf(id, holder);
        if (found) {
            for (uint256 i=pos; i<_holders[id].length-1; i++)
                _holders[id][i] = _holders[id][i+1];
            _holders[id].pop();
        }
    }

}