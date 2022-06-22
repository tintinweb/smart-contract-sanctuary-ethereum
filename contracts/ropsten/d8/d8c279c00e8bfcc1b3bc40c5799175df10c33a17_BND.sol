/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

pragma solidity ^0.8.0;
/** 

    SPDX-License-Identifier: GPL-3.0

**/

contract BND {
    /**
        Building token.
    **/
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => string) private _permisson;
    

    string private _name;
    string private _symbol;
    address private _owner;

    uint256 private _totalSupply;
    uint256 private _maxSuply;
    uint private _decimals;
    


    constructor () {

        _name = "BinanceDoge";
        _symbol = "BND";
        _owner = msg.sender;
        _totalSupply = 0;
        _mint(_owner, 1000000000);
        _decimals = 18;

    }

    function name() public view virtual returns(string memory){ return _name; }
    function symbol() public view virtual returns(string memory){ return _symbol; }
    function decimals() public view virtual returns(uint8) {return 18;}
    function totalSupply() public view virtual returns(uint256) {return _totalSupply;}
    function maxSuply() public view virtual returns(uint256){ return _maxSuply; }

    /**
                        (    )
        FUNDS MANAGER  (  *   )
                        (    ) _ _
    **/

    function balanceOf(address account) public view returns(uint256){ return _balances[account]; }

    function _transfer(address _from, address _to, uint256 count) internal virtual { 

        require(_from != address(0), "BND::Transaction from zero.");
        require(_to != address(0), "BND::Transaction to zero.");
        require(count > 0, "BND::Transfer amount need to be more than 0.");

        uint256 _formBal = _balances[_from];
        require(_formBal >= count, "BND::Not enough balance!");

        unchecked {
            _balances[_from] = _formBal - count;
        }
        _balances[_to] += count;

     }

    function transfer(address from, address to, uint256 count)public virtual returns (bool){ _transfer(from, to, count); }
    function _mint(address account, uint256 count) internal virtual { require(msg.sender == _owner, "Not owner sad :("); _totalSupply += count; _balances[account] += count; }
    function mint(address account, uint256 count) public virtual returns(bool) { _mint(account, count); }

}